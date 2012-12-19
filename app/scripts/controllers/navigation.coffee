
define [
  'jquery',
  'underscore'
  'spine',
  'text!views/navigation.html'
  'models/session'
], ($, _, Spine, navigationTemplate, Session) ->
  
  class Navigation extends Spine.Controller
    constructor: ->
      super
    
    className: 'navbar navbar-static-top navbar-inverse'
    
    events:
      'click ul > li > a' : 'makeLinkActive'
    
    makeLinkActive: (event) =>
      return if event.target.tagName.toLowerCase() isnt 'a'
      $(event.target).parent().addClass('active').siblings().removeClass('active')
    
    render: =>
      @html _.template navigationTemplate, session: Session.first()
      @
  
