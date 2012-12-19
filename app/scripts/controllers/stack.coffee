define [
  'jquery'
  'underscore'
  'spine'
  'controllers/home'
  'controllers/dashboard'
], ($, _, Spine, Home, Dashboard) ->
  
  class Stack extends Spine.Stack
    constructor: ->
      super
    
    controllers:
      Home: Home
      Dashboard: Dashboard
      