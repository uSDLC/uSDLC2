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
  
  load_requirements = -> @requires(
    "/client/edit_source.coffee"
    '/client/dialog.coffee')
    
  load_file_list = ->
    path = "/server/http/files.coffee"
    exclude = cludes[1].value
    include = cludes[0].value
    selector = "exclude=#{exclude}&include=#{include}"
    args = "project=#{usdlc.project}&type=json"
    
    @json "#{path}?#{args}&#{selector}"
    
  update_icon_path = (dtree) ->
    for key, path of dtree.icon
      dtree.icon[key] = "/ext/dtree/#{path}"
        
  build_tree = ->
    next_id = 0
    branch = (parent, item) ->
      id = ++next_id
      item_data = "{value:'#{item.name}'," +
        "path:'#{item.path}',category:'#{item.category}'}"
      path = "javascript:usdlc.edit_source(#{item_data})"
      dtree.add(id, parent, item.name, path)
      branch(id, child) for child in item.children ? []
    branch(-1, name: usdlc.project, children: @files)
    tree.html(dtree.toString())
    nodes = tree.find('div.dTreeNode a[id]')
    branches = tree.find('div.dTreeNode')
    
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
    selected = tree.find('div.dTreeNode a.nodeSel')
    eval(selected.attr('href'))
  
  filter_tree = (text) ->
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
  
  open_dialog = ->
    @dlg = @dialog
      name: 'Source...'
      init: (dlg) =>
        dlg.append form = $('form.tree_filer')
        search_for = form.find('div.input input').keyup ->
          return if (search = search_for.val()) is last_search
          filter_tree(last_search = search)
        last_search = search_for.val()
        search_by = form.find('div.search_by').buttonset()
        tree = form.find('div.tree')
        cludes = form.find('div.clusions input')
        
        usdlc.dtree = dtree = new dTree('usdlc.dtree')
        update_icon_path(dtree)
        dtree.config.inOrder = true
        dtree.config.folderLinks = false
        
        form.keydown (event) ->
          switch event.which
            when 13 then select_from_tree()
            when 38 then move(-1)
            when 40 then move(1)
      fill: (dlg) =>
        steps(
          load_file_list
          build_tree
        )
      dialog_options
      
  steps(
    load_packages
    load_requirements
    open_dialog
  )
