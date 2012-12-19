define [
  'spine',
  'text!views/dashboard.html'
], (Spine, dashboardTemplate) ->
  
  class Dashboard extends Spine.Controller
    constructor: ->
      super
      @routes
        '!/dashboard': =>
          App.navigation.render()
          @render().active()
    
    className: 'dashboard'
    
    render: =>
      @html _.template dashboardTemplate
      $('#app-body').append @$el
      @

