# Copyright (C) 2013 paul@marrington.net, see /GPL for license

dialog_options =
  width:      'auto'
  autoResize: true
  minHeight:  50
  
# title:required, form:selector, position:{my:'',at:'',of:''}
# tree_action:function_name
module.exports = (options, next) ->
  tree_action = options.tree_action; last_search = ''
  dtree = branches = null; form = tree = nodes = null

  roaster.clients '/client/dialog.coffee', (dialog) -> dialog
    name: options.title
    init: initialise_dialog
    fill: fill_tree
    dialog_options
    options

  initialise_dialog = (dlg) =>
    dlg.append form = $(options.form)
    search_for = dlg.search_for = form.find('input.search_for')
    search_for.keyup ->
      return if (search = search_for.val()) is last_search
      filter_tree(last_search = search)
    last_search = search_for.val()
    tree = form.find('div.tree')
    
    form.keydown (event) ->
      switch event.which
        when 13 then select_from_tree()
        when 38 then move(-1)
        when 40 then move(1)
    set_focus = -> search_for.focus()
    dlg.on "dialogfocus", set_focus
    dlg.on "dialogcreate", set_focus
    search_for.focus -> search_for.select()
    next null, dlg
        
  fill_tree = -> roaster.packages 'dtree', ->
    usdlc.dtree = dtree = new dTree(options.title)
    for key, path of dtree.icon
      dtree.icon[key] = "/ext/dtree/#{path}"
    dtree.config.inOrder = true
    dtree.config.folderLinks = false
    dtree.config.useCookies = false
    
    next_id = 0
    branch = (parent, item) ->
      id = ++next_id
      item_data = JSON.stringify(item)
      path = "javascript:usdlc.#{tree_action}(#{item_data})"
      # don't show empty branches
      if not empty_branch(item)
        dtree.add(id, parent, item.name, path)
        branch(id, child) for child in item.children ? []
    branch(-1, name: usdlc.project, children: options.data)
    tree.html(dtree.toString())
    nodes = tree.find('div.dTreeNode a[id]')
    branches = tree.find('div.dTreeNode')
    branches.first().click -> usdlc.dtree.closeAll()
    form.find('a,input').attr('tabindex', '-1')
    
  empty_branch = (item) ->
    return false if not item.children?
    return true if item.children.length is 0
    for item in item.children
      return false if not empty_branch(item)
    return true
    
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
