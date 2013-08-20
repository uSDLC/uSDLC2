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
  form = null
  
  load_packages = -> @package "dtree"
  
  load_requirements = -> @requires(
    "/client/edit_source.coffee"
    '/client/dialog.coffee')
    
  tree_container = null
  
  load_file_list = ->
    path = "/server/http/files.coffee"
    cludes = form.find('div.clusions input')
    exclude = cludes[1].value
    include = cludes[0].value
    selector = "exclude=#{exclude}&include=#{include}"
    args = "project=#{usdlc.project}&type=json"
    
    @json "#{path}?#{args}&#{selector}"
    
  update_icon_path = (dtree) ->
    for key, path of dtree.icon
      dtree.icon[key] = "/ext/dtree/#{path}"
        
  build_tree = ->
    dtree = usdlc.dtree = new dTree('usdlc.dtree')
    update_icon_path(dtree)
    dtree.config.inOrder = true
    dtree.config.folderLinks = false
    next_id = 0
    branch = (parent, item) ->
      id = ++next_id
      item_data = "{value:'#{item.name}'," +
        "path:'#{item.path}',category:'#{item.category}'}"
      path = "javascript:usdlc.edit_source(#{item_data})"
      dtree.add(id, parent, item.name, path)
      branch(id, child) for child in item.children ? []
    branch(-1, name: usdlc.project, children: @files)
    tree_container.html(dtree.toString())
    
  open_dialog = ->
    @dlg = @dialog
      name: 'Source...'
      init: (dlg) =>
        dlg.append form = $('form.tree_filer')
        form.find('div.search_by').buttonset()
        tree_container = form.find('div.tree')
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
