define [
  'spine',
  'text!views/pricing.html'
], (Spine, pricingTemplate) ->
  
  class Pricing extends Spine.Controller
    constructor: ->
      super
      @routes
        '/pricing': =>
          App.navigation.render()
          @render().active()
    
    className: 'pricing main-stack'
    
    render: =>
      @html _.template pricingTemplate
      $('#app-body').append @$el
      @

