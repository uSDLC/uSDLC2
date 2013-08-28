# Copyright (C) 2013 paul@marrington.net, see GPL for license

dialog_options =
  width:      'auto'
  autoResize: true
  minHeight:  50
  title:      'Files...'
  position:   { my: "left", at: "left+610", of: window }
  closeOnEscape: false
  fix_height_to_window: 10
  
module.exports = ->
  form = tree = search_by = cludes = search_for = nodes = null
  last_search = ''; dtree = branches = null
  
  load_packages = -> @package "dtree"
  
  search_type = ->
    search_by.find(':radio:checked').attr('id')[-4..]
  
  load_requirements = -> @requires(
    "/client/edit_source.coffee"
    '/client/dialog.coffee')
    
  load_file_list = ->
    path = "/server/http/files.coffee"
    exclude = cludes[1].val()
    include = cludes[0].val()
    selector = "exclude=#{exclude}&include=#{include}"
    search = "search=#{search_type()}&re=#{search_for.val()}"
    args = "project=#{usdlc.project}&type=json"
    @json "#{path}?#{args}&#{selector}&#{search}"
    
  update_icon_path = (dtree) ->
    for key, path of dtree.icon
      dtree.icon[key] = "/ext/dtree/#{path}"
      
  empty_branch = (item) ->
    return false if not item.children?
    return true if item.children.length is 0
    for item in item.children
      return false if not empty_branch(item)
    return true
        
  build_tree = ->
    usdlc.dtree = dtree = new dTree('usdlc.dtree')
    update_icon_path(dtree)
    dtree.config.inOrder = true
    dtree.config.folderLinks = false
    
    next_id = 0
    branch = (parent, item) ->
      id = ++next_id
      item_data = "{value:'#{item.name}'," +
        "path:'#{item.path}',category:'#{item.category}'}"
      path = "javascript:usdlc.edit_source(#{item_data})"
      # don't show empty branches
      if not empty_branch(item)
        dtree.add(id, parent, item.name, path)
        branch(id, child) for child in item.children ? []
    branch(-1, name: usdlc.project, children: @files)
    tree.html(dtree.toString())
    nodes = tree.find('div.dTreeNode a[id]')
    branches = tree.find('div.dTreeNode')
    usdlc.dtree.openAll() if search_type() is 'grep'
    branches.first().click -> usdlc.dtree.closeAll()
    
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
      
  fill_tree = =>
    steps(
      load_file_list
      build_tree
    )
  
  open_dialog = ->
    @dlg = @dialog
      name: 'Source...'
      init: (dlg) =>
        dlg.append form = $('form.tree_filer')
        search_for = form.find('div.input input')
        search_for.keyup ->
          return if (search = search_for.val()) is last_search
          filter_tree(last_search = search)
        search_for.change ->
          if search_type() is 'grep'
            usdlc.grep = search_for.val()
            fill_tree()
        last_search = search_for.val()
        search_by = form.find('div.search_by').buttonset()
        $('#search_by_name').click ->
          search_for.val('')
          fill_tree()
        tree = form.find('div.tree')
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
      fill: fill_tree
      dialog_options
      
  steps(
    load_packages
    load_requirements
    open_dialog
  )
