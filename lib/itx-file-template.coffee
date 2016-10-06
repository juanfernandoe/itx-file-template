ItxFileTemplateView = require './itx-file-template-view'
{CompositeDisposable} = require 'atom'

SelectView = require './select-view'
path   = require 'path'
fsPlus = require 'fs-plus'
_      = require 'underscore'
fs     = require 'fs'


module.exports = ItxFileTemplate =
  itxFileTemplateView: null
  modalPanel: null
  subscriptions: null
  templatesRoot: null
  assetsRoot: null

  activate: (state) ->
    #alert("ok")
    @itxFileTemplateView = new ItxFileTemplateView(state.itxFileTemplateViewState)
    #@modalPanel = atom.workspace.addModalPanel(item: @itxFileTemplateView.getElement(), visible: false)

    @templatesRoot = path.join atom.getUserInitScriptPath(), '../', 'itx-templates'
    @assetsRoot    = path.join __dirname, "../", "assets"

    fsPlus.makeTreeSync(@templatesRoot)

    unless fsPlus.existsSync( path.join(@templatesRoot, "BaseTemplate") )
      fsPlus.copySync( path.join(@assetsRoot, "BaseTemplate"), path.join(@templatesRoot, "BaseTemplate") )

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    #@subscriptions.add atom.commands.add 'atom-workspace', 'itx-file-template:toggle': => @toggle()

    @subscriptions.add atom.commands.add '.tree-view .selected', 'itx-file-template:create-files-from-template', (e) => @createFilesFromTemplate(e)
    @subscriptions.add atom.commands.add 'atom-workspace', 'itx-file-template:open-temlates-folder', (e) => @openTemplatesFolder(e)
    @subscriptions.add atom.commands.add 'atom-workspace', 'itx-file-template:open-temlates-folder-in-atom', (e) => @openTemplatesFolderInAtom(e)

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @itxFileTemplateView.destroy()

  serialize: ->
    itxFileTemplateViewState: @itxFileTemplateView.serialize()

  toggle: ->
    console.log 'ItxFileTemplate was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()


  openTemplatesFolder: (e) ->
    switch require('os').platform()
      when 'darwin'
        require('child_process').exec "open #{@templatesRoot}"
      when 'linux'
        require('child_process').exec "open #{@templatesRoot}"
      when 'win32'
        require('child_process').exec "explorer #{@templatesRoot}"

  openTemplatesFolderInAtom: (e) ->
    switch require('os').platform()
      when 'darwin'
        require('child_process').exec "open -a Atom.app #{@templatesRoot}"
      when 'linux'
        require('child_process').exec "open #{@templatesRoot}"
      when 'win32'
        require('child_process').exec "atom #{@templatesRoot}"

  scanTemplatesFolder: ->

    templates = []

    for item in (fs.readdirSync(@templatesRoot))

      fullPathToFolder = path.join @templatesRoot, item
      continue unless fsPlus.isDirectorySync(fullPathToFolder)

      fullPathToIndexIndex = path.join fullPathToFolder, "index.js"
      continue unless fsPlus.isFileSync(fullPathToIndexIndex)

      try
        delete require.cache[fullPathToIndexIndex]
        templateObject = require(fullPathToIndexIndex)
        templateObject.rootPath = fullPathToFolder
        throw "Template object does not contain 'name' field" unless templateObject.name
        throw "Template object does not contain 'rules' field"  unless templateObject.rules
        templates.push templateObject
      catch error
        console.error  "Template index '#{fullPathToIndexIndex}' error: #{error}"

    return templates

  createFilesFromTemplate: (e) ->

    itemPath = e.currentTarget?.getPath?()

    if itemPath
        new SelectView(itemPath, @scanTemplatesFolder())
