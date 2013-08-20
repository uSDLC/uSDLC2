# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    usdlc.richCombo
      name: 'projects'
      label: 'Projects'
      toolbar: 'uSDLC,1'
      items: (next) ->
        projects = roaster.environment.projects
        next (key.replace(/_/g, ' ') for key, value of projects).sort()
      selected: -> usdlc.project.replace /_/g, ' '
      select: (value) ->
        if value is 'create'
          alert("Under Construction")
        else
          usdlc.setProject value.replace(/\s/g, '_')
          page = usdlc.projectStorage('url') ? 'Index'
          usdlc.edit_page page
