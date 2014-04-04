# Copyright (C) 2013 paul@marrington.net, see /GPL for license

dialog_options =
  width:      'auto'
  autoResize: true
  minHeight:  50
  title:      'Files...'
  position:   { my:"left top", at:"left+610 top",of: window }
  closeOnEscape: false
  
form = tree = search_by = cludes = search_for = nodes = null
last_search = ''; dtree = branches = data = files = null
filer = "/server/http/files.coffee"

module.exports = ->
  tree_actions =
    edit: (_data) ->
      data = _data
      if data.is_dir
        usdlc.dtree.o(data.id)
      else
        usdlc.edit_source(data)
    'delete': (_data) ->
      data = _data
      url = "#{filer}?cmd=rm&path=#{data.path}"
      roaster.request.json url, fill_tree
    move: (_data) ->
      roaster.clients "/client/autocomplete.coffee",
      (autocomplete) ->
        data = _data
        tree_actions.url = data.path
        autocomplete
          title: 'Move/Rename...'
          source: (req, rsp) ->
            if req.term
              rsp [req.term, data.value]
            else
              rsp [data.value]
          select: (selected) ->
            url = "#{filer}?cmd=mv&from=#{tree_actions.url}"+
                  "&to=#{selected.value}"
            roaster.request.json url, fill_tree
    'new': (_data) ->
      roaster.clients "/client/autocomplete.coffee",
      (autocomplete) ->
        data = _data
        autocomplete
          title: 'New...'
          source: (req, rsp) -> rsp [req.term, data.value]
          select: (selected) ->
            roaster.request.json "#{filer}?cmd=mk"+
                  "&path=#{data.path}&name=#{selected.value}",
                  fill_tree
  usdlc.tree_action = tree_actions.edit
  
  search_type = ->
    search_by.find(':radio:checked').attr('id')[-4..]
  
  empty_branch = (item) ->
    return false if not item.children?
    return true if item.children.length is 0
    for item in item.children
      return false if not empty_branch(item)
    return true
        
  build_tree = ->
    usdlc.dtree = dtree = new dTree('usdlc.dtree')
    for key, path of dtree.icon
      dtree.icon[key] = "/ext/dtree/#{path}"
    dtree.config.inOrder = true
    dtree.config.folderLinks = true
    dtree.config.useCookies = true
    
    next_id = 0; no_search = search_for.val().length is 0
    branch = (parent, item) ->
      id = ++next_id
      is_dir = item.children?
      item.path ?= '~'+usdlc.project
      item_data = "{value:'#{item.name}'," +
        "path:'#{item.path}',category:'#{item.category}',"+
        "is_dir:#{is_dir}, id:#{id - 1}}"
      path = "javascript:usdlc.tree_action(#{item_data})"
      # don't show empty branches
      if no_search or not empty_branch(item)
        dtree.add(id, parent, item.name, path)
        if is_dir
          if item.children.length is 0
            branch(id, name:'')
          else
            branch(id, child) for child in item.children
    branch(-1, name: usdlc.project, children: files)
    tree.html(dtree.toString())
    nodes = tree.find('div.dTreeNode a[id]')
    branches = tree.find('div.dTreeNode')
    usdlc.dtree.openAll() if search_type() is 'grep'
    branches.first().click -> usdlc.dtree.closeAll()
    form.find('.tree_filer').
      find('a,input').attr('tabindex', '-1')
    tree.contextmenu
      menu: '#tree_filer_menu'
      delegate: '.dTreeNode'
      select: (event, ui) ->
        usdlc.tree_action = tree_actions[ui.cmd]
        ui.target.context.click()
        usdlc.tree_action = tree_actions.edit
    
  move = (dir) ->
    selected = tree.find('div.dTreeNode a.nodeSel')
    if not selected.length
      next = if dir is -1 then nodes.length else 0
    else
      nodes.each (index) ->
        if selected.is(@) then next = index; return false
        return true
    while (next += dir) >= 0 and next < nodes.length
      node = $(nodes[next])
      if node.is(':visible')
        selected.removeClass('nodeSel').addClass('node')
        node.removeClass('node').addClass('nodeSel')
        return
  
  select_from_tree = ->
    return if search_type() is 'grep' and not usdlc.grep
    selected = tree.find('div.dTreeNode a.nodeSel')
    eval(selected.attr('href'))
  
  filter_tree = (text) ->
    return if search_type() is 'grep'
    re = new RegExp(text, 'i')
    first = true
    usdlc.dtree.closeAll()
    branches.addClass('hidden')
    nodes.each (index) ->
      div = (node = $(@)).parent()
      parents = div.parents('div.clip').prev()
      if re.test(node.text())
        div.removeClass('hidden')
        parents.removeClass('hidden')
        id = node.attr('id').match(/\d+/)[0]
        usdlc.dtree.openTo(id, first)
        first = false
      return true
      
  fill_tree = ->
    if form.find('.filter_tree:checked').length
      exclude = cludes[1].val()
      include = cludes[0].val()
    else
      include = exclude = ''
    selector = "exclude=#{exclude}&include=#{include}"
    search = "search=#{search_type()}&re=#{search_for.val()}"
    args = "project=#{usdlc.project}&type=json"
    url = "#{filer}?#{args}&#{selector}&#{search}"
    roaster.request.json url, (err, list) ->
      build_tree files = list
  
  open_dialog = (edit_source, dialog) ->
    dialog
      name: 'Source...'
      init: (dlg) =>
        dlg.append form = $('#tree_filer')
        search_for = form.find('input.search_for')
        search_for.keyup ->
          return if (search = search_for.val()) is last_search
          filter_tree(last_search = search)
        search_for.change ->
          if search_type() is 'grep'
            usdlc.grep = search_for.val()
            fill_tree()
        last_search = search_for.val()
        search_by = form.find('div.search_by').buttonset()
        form.find('.search_by_name').click ->
          search_for.val('')
          fill_tree()
        search_by.click ->
          setTimeout (-> search_for.focus()), 200
        tree = form.find('div.tree')
        form.find('.filter_tree').change -> fill_tree()
        cludes = form.find('div.clusions input')
        cludes = ($(input) for input in cludes)
        cludes[0].val usdlc.projectStorage('include') ? ''
        cludes[1].val usdlc.projectStorage('exclude') ? ''
        cludes[0].on 'change', ->
          usdlc.projectStorage('include', cludes[0].val())
          fill_tree()
        cludes[1].on 'change', ->
          usdlc.projectStorage('exclude', cludes[1].val())
          fill_tree()
        
        form.keydown (event) ->
          switch event.which
            when 13 then select_from_tree()
            when 38 then move(-1)
            when 40 then move(1)
        set_focus = -> search_for.focus()
        dlg.on "dialogfocus", set_focus
        dlg.on "dialogcreate", set_focus
        search_for.focus -> search_for.select()
      fill: -> fill_tree()
      dialog_options
     
  roaster.packages 'dtree', ->
    roaster.clients "/client/edit_source.coffee",
      '/client/dialog.coffee', open_dialog
