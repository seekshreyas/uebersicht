Widget   = require './widget.coffee'
loader   = require './widget_loader.coffee'
paths    = require 'path'

module.exports = (directoryPath) ->
  api = {}

  widgets  = {}
  changeCallback = ->

  init = ->
    watcher = require('chokidar').watch directoryPath
    watcher
      .on 'change', (filePath) ->
        registerWidget loadWidget(filePath) if isWidgetPath(filePath)
      .on 'add',    (filePath) ->
        registerWidget loadWidget(filePath) if isWidgetPath(filePath)
      .on 'unlink', (filePath) ->
        deleteWidget widgetId(filePath) if isWidgetPath(filePath)

    console.log 'watching', directoryPath
    api

  api.watch = (callback) ->
    changeCallback = callback
    init()

  api.widgets = -> widgets

  api.get = (id) -> widgets[id]

  api.path = directoryPath

  loadWidget = (filePath) ->
    id = widgetId filePath

    try
      definition    = loader.loadWidget(filePath)
      definition.id = id if definition?
      Widget definition
    catch e
      notifyError filePath, e
      console.log 'error in widget', id+':', e.message

  registerWidget = (widget) ->
    return unless widget?
    console.log 'registering widget', widget.id
    widgets[widget.id] = widget
    notifyChange widget.id, widget

  deleteWidget = (id) ->
    return unless widgets[id]?
    console.log 'deleting widget', id
    delete widgets[id]
    notifyChange id, 'deleted'

  notifyChange = (id, change) ->
    changes = {}
    changes[id] = change
    changeCallback changes

  notifyError = (filePath, error) ->
    changeCallback null, prettyPrintError(filePath, error)

  prettyPrintError = (filePath, error) ->
    errStr = error.toString?() or String(error.message)

    # coffeescipt errors will have [stdin] when prettyPrinted (because they are
    # parsed from stdin). So lets replace that with the real file path
    if errStr.indexOf("[stdin]") > -1
      errStr = errStr.replace("[stdin]", filePath)
    else
      errStr = filePath + ': ' + errStr

    errStr

  widgetId = (filePath) ->
    fileParts = filePath.replace(directoryPath, '').split(/\/+/)
    fileParts = (part for part in fileParts when part)

    fileParts.join('-').replace(/\./g, '-')

  isWidgetPath = (filePath) ->
    filePath.match(/\.coffee$/) ? filePath.match(/\.js$/)

  api
