
define [
  'jquery',
  'underscore'
  'spine',
  'text!views/footer.html'
], ($, _, Spine, footerTemplate) ->
  
  class Footer extends Spine.Controller
    constructor: ->
      super
    
    render: =>
      @html _.template footerTemplate
      @
  
