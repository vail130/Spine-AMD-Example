define [
  'spine',
  'text!views/home.html'
], (Spine, homeTemplate) ->
  
  class Home extends Spine.Controller
    constructor: ->
      super
      @routes
        '!/home': =>
          App.navigation.render()
          @render().activate()
    
    className: 'home'
    
    render: =>
      @html _.template homeTemplate
      $('#app-body').append @$el
      @

