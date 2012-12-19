define [
  'jquery'
  'underscore'
  'spine'
  'text!views/structure.html'
  'controllers/navigation'
  'controllers/footer'
  'models/session'
  'models/account'
], ($, _, Spine, structureTemplate, Navigation, Footer, Session, Account) ->
  
  class App extends Spine.Controller
    constructor: ->
      super
      @html structureTemplate
      
      @navigation = new Navigation el: $('#navigation')
      @navigation.render()
      @footer = new Footer el: $('#footer')
      @footer.render()
      
      sessionDeferred = $.Deferred()
      sessionPromise = sessionDeferred.promise()
      
      Session.one 'refresh', => sessionDeferred.resolve()
      Session.fetch()
      
      $.when(
        sessionPromise
      ).done =>
        masterDeferred = $.Deferred()
        @masterPromise = masterDeferred.promise()
        
        if Session.first().id?
          @loadData =>
            masterDeferred.resolve()
            if window.location.hash in ['', '#!']
              window.location.hash = '#!/dashboard'
        
        else
          masterDeferred.resolve()
          if window.location.hash in ['', '#!']
            window.location.hash = '#!/home'
    
    loadData: (callback) =>
      #
      # Create deferred objects for each model and set them to resolve on refresh
      #
      accountDeferred = $.Deferred()
      Account.one 'refresh', => accountDeferred.resolve()
      
      #
      # Fetch each model's records here
      #
      Account.fetch()
      
      $.when(
        # List all deferred objects here
        accountDeferred
      ).done =>
        @navigation.render()
        callback?()
      
      @
