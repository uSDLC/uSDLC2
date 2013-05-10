# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    usdlc.richCombo
      name: 'projects'
      label: 'Projects'
      toolbar: 'usdlc'
      items: (key for key, value of roaster.environment.projects).sort()
      selected: -> localStorage.project.replace /_/g, ' '
      select: (value) ->
        if value is 'create'
          alert("Under Construction")
        else
          localStorage.project = value.replace(/\s/g, '_')
          page = localStorage["#{localStorage.project}_url"] ? 'Index'
          usdlc.edit_page page