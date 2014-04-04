# Copyright (C) 2014 paul@marrington.net, see /GPL for license

dialog_options =
  width:      'auto'
  autoResize: true
  minHeight:  50
  
filer = "/server/http/files.coffee"
  
class DirTree
  constructor: (@id, @option_name) ->
    @opt = @option_list[@option_name]
    roaster.packages 'dtree', =>
      roaster.clients "/client/edit_source.coffee",
        '/client/dialog.coffee', (params...) =>
          @tree_action = @tree_actions.edit
          @open_dialog params...
  option_list:
    Project:
      dialog:
        position: {
          my:"left top", at:"left+610 top",of: window }
        closeOnEscape: false
      hide: []
      name_hint: "pattern..."
      on_select: (data) =>
        if data.is_dir
          @dtree.o(data.id)
        else
          usdlc.edit_source(data)
      on_keyup: =>
        search = @search_for.val()
        return if (search) is @last_search
        @filter_tree(@last_search = search)
    New_Project:
      dialog:
        title: 'New Project...'
        closeOnEscape: true
      hide: ['.search_by', '.filters']
      name_hint: "project display name"
      on_select: (data) =>
        if (name = @search_for.val()).length > 0
          roaster.request.json \
          "/client/ckeditor/projects.coffee?add="+
          name+"&path="+data.path, ->
            usdlc.setProject name.replace(/\s/g, '_')
            usdlc.edit_page 'Index'
          dialog_window.dialog 'close'
        else
          @search_for.attr 'placeholder',
            "Enter project name first!"
      on_keyup: =>
        
  tree_actions:
    edit: (@data) => @opt.on_select @data
    'delete': (@data) =>
      url = "#{filer}?cmd=rm&path=#{data.path}"
      roaster.request.json url, @fill_tree
    move: (@data) =>
      roaster.clients "/client/autocomplete.coffee",
      (autocomplete) ->
        tree_actions.url = @data.path
        autocomplete
          title: 'Move/Rename...'
          source: (req, rsp) =>
            if req.term
              rsp [req.term, @data.value]
            else
              rsp [@data.value]
          select: (selected) =>
            url = "#{filer}?cmd=mv&from=#{@tree_actions.url}"+
                  "&to=#{@selected.value}"
            roaster.request.json url, @fill_tree
    'new': (@data) =>
      roaster.clients "/client/autocomplete.coffee",
      (autocomplete) =>
        autocomplete
          title: 'New...'
          source: (req, rsp) => rsp [req.term, @data.value]
          select: (selected) =>
            roaster.request.json "#{filer}?cmd=mk"+
              "&path=#{@data.path}&name=#{@selected.value}",
              @fill_tree
  search_type: ->
    @search_by.find(':radio:checked').attr('id')[-4..]
        
  build_tree: ->
    @dtree = new dTree('usdlc.dtree.'+@id)
    for key, path of @dtree.icon
      @dtree.icon[key] = "/ext/dtree/#{path}"
    @dtree.config.inOrder = true
    @dtree.config.folderLinks = true
    @dtree.config.useCookies = true
    
    next_id = 0; no_search = @search_for.val().length is 0
    branch = (parent, item) =>
      id = ++next_id
      is_dir = item.children?
      item.path ?= '~'+usdlc.project
      item_data = "{value:'#{item.name}'," +
        "path:'#{item.path}',category:'#{item.category}',"+
        "is_dir:#{is_dir}, id:#{id - 1}}"
      instance = "usdlc.dir_trees['#{@id}']"
      path = "javascript:#{instance}.tree_action(#{item_data})"
      # don't show empty branches
      if no_search or not empty_branch(item)
        @dtree.add(id, parent, item.name, path)
        if is_dir
          if item.children.length is 0
            branch(id, name:'')
          else
            branch(id, child) for child in item.children
    branch(-1, name: usdlc.project, children: @files)
    @tree.html(@dtree.toString())
    @nodes = @tree.find('div.dTreeNode a[id]')
    @branches = @tree.find('div.dTreeNode')
    @dtree.openAll() if @search_type() is 'grep'
    @branches.first().click -> @dtree.closeAll()
    @form.find('.tree_filer').
      find('a,input').attr('tabindex', '-1')
    @tree.contextmenu
      menu: '#tree_filer_menu'
      delegate: '.dTreeNode'
      select: (event, ui) ->
        @tree_action = @tree_actions[ui.cmd]
        ui.target.context.click()
        @tree_action = @tree_actions.edit
  
  empty_branch: (item) ->
    return false if not item.children?
    return true if item.children.length is 0
    for item in item.children
      return false if not @empty_branch(item)
    return true
  
  move: (dir) ->
    selected = @tree.find('div.dTreeNode a.nodeSel')
    if not selected.length
      next = if dir is -1 then @nodes.length else 0
    else
      @nodes.each (index) ->
        return true if not selected.is(@)
        next = index; return false
    while (next += dir) >= 0 and next < @nodes.length
      node = $(@nodes[next])
      if node.is(':visible')
        selected.removeClass('nodeSel').addClass('node')
        node.removeClass('node').addClass('nodeSel')
        return
  
  select_from_tree: ->
    return if @search_type() is 'grep' and not @grep
    selected = @tree.find('div.dTreeNode a.nodeSel')
    eval(selected.attr('href'))
  
  filter_tree: (text) ->
    return if @search_type() is 'grep'
    re = new RegExp(text, 'i')
    first = true
    @dtree.closeAll()
    @branches.addClass('hidden')
    @nodes.each (index) ->
      div = (node = $(@)).parent()
      parents = div.parents('div.clip').prev()
      if re.test(node.text())
        div.removeClass('hidden')
        parents.removeClass('hidden')
        id = node.attr('id').match(/\d+/)[0]
        @dtree.openTo(id, first)
        first = false
      return true
      
  fill_tree: ->
    if @form.find('.filter_tree:checked').length
      exclude = @cludes[1].val()
      include = @cludes[0].val()
    else
      include = exclude = ''
    selector = "exclude=#{exclude}&include=#{include}"
    search = "search=#{@search_type()}&re=#{@search_for.val()}"
    args = "project=#{@id}&type=json"
    url = "#{filer}?#{args}&#{selector}&#{search}"
    roaster.request.json url, (err, list) =>
      @build_tree @files = list
  
  open_dialog: (edit_source, dialog) ->
    dialog
      name: @id
      init: (dlg) =>
        dlg.append @form = $('#tree_filer').clone()
        @tree = @form.find('div.tree')
        @form.find(el).hide() for el in @opt.hide
        @search_for = @form.find('input.search_for')
        @search_for.keyup @opt.on_keyup
        @search_for.attr 'placeholder', @opt.name_hint
        @search_for.change =>
          if @search_type() is 'grep'
            @grep = @search_for.val()
            @fill_tree()
        @last_search = @search_for.val()
        @search_by = @form.find('div.search_by').buttonset()
        @form.find('.search_by_name').click ->
          @search_for.val('')
          @fill_tree()
        @search_by.click =>
          setTimeout (=> @search_for.focus()), 200
        @form.find('.filter_tree').change -> @fill_tree()
        @cludes = @form.find('div.clusions input')
        @cludes = ($(input) for input in @cludes)
        @cludes[0].val usdlc.projectStorage('include') ? ''
        @cludes[1].val usdlc.projectStorage('exclude') ? ''
        @cludes[0].on 'change', =>
          usdlc.projectStorage('include', @cludes[0].val())
          @fill_tree()
        @cludes[1].on 'change', =>
          usdlc.projectStorage('exclude', @cludes[1].val())
          @fill_tree()
        
        @form.keydown (event) =>
          switch event.which
            when 13 then @select_from_tree()
            when 38 then @move(-1)
            when 40 then @move(1)
        set_focus = => @search_for.focus()
        dlg.on "dialogfocus", set_focus
        dlg.on "dialogcreate", set_focus
        @search_for.focus => @search_for.select()
      fill: => @fill_tree()
      @opt.dialog, dialog_options
     
usdlc.dir_trees = trees = {}

module.exports =
  home: ->
    if not trees['~']
      trees['~'] = new DirTree('~','New_Project')
    return trees['~']
  project: (name) ->
    if not trees[name]
      trees[name] = new DirTree(name, 'Project')
      trees[name].option_list.Project.dialog.title = name