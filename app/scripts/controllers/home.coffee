define [
  'spine',
  'text!views/home.html'
], (Spine, homeTemplate) ->
  
  class Home extends Spine.Controller
    constructor: ->
      super
      @routes
        '/home': =>
          App.navigation.render()
          @render().activate()
    
    className: 'home main-stack'
    
    render: =>
      @html _.template homeTemplate
      $('#app-body').append @$el
      @

