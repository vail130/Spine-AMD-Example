define [
  'jquery'
  'underscore'
  'spine'
  'controllers/home'
  'controllers/pricing'
  'controllers/projects/work'
  'controllers/settings/settings'
], ($, _, Spine, Home, Pricing, Work, Settings) ->
  
  class Stack extends Spine.Stack
    constructor: ->
      super
    
    controllers:
      Home: Home
      Pricing: Pricing
      Work: Work
      Settings: Settings
      ###
      Learn: Learn
      Signup: Signup
      Signin: Signin
      Terms: Terms
      Privacy: Privacy
      ModalForm: ModalForm
      ###
      