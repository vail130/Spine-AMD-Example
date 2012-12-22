require.config
  shim:
    'spin':
      exports: 'Spinner'
    'jquery':
      exports: '$'
    'underscore':
      exports: '_'
    'spine':
      deps: ['underscore', 'jquery']
      exports: 'Spine'
    'bootstrap':
      deps: ['jquery', 'moment']
    'fileupload':
      deps: ['jquery']
    'iframe-transport':
      deps: ['jquery']
    'jquery-ui':
      deps: ['jquery']

  paths:
    'es5-shim': 'vendor/es5-shim.min'
    'jquery': 'vendor/jquery.min'
    'jquery-ui': 'vendor/jquery-ui-1.9.2.min'
    'underscore': 'vendor/underscore.min'
    'spine': 'vendor/spine-build'
    'bootstrap': 'vendor/bootstrap.min'
    'spin': 'vendor/spin.min'
    'moment': 'vendor/moment.min'
    'fileupload': 'vendor/fileupload/jquery.fileupload'
    'iframe-transport': 'vendor/fileupload/jquery.iframe-transport'
 
require [
  'underscore'
  'jquery'
  'jquery-ui'
  'bootstrap'
  'fileupload'
  'iframe-transport'
  'spine'
  'app'
  'controllers/stack'
], (_, $, JUI, Bootstrap, Fileupload, IframeTransport, Spine, App, Stack) ->
  
  $ ->
    window.App = new App el: $('#application')
    $.when(window.App.masterPromise).done ->
      App.stack = new Stack
      Spine.Route.setup()
