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
            if window.location.hash in ['', '#']
              window.location.hash = '#/projects'
        
        else
          masterDeferred.resolve()
          if window.location.hash in ['', '#']
            window.location.hash = '#/home'
    
    loadData: (callback) =>
      accountDeferred = $.Deferred()
      Account.one 'refresh', => accountDeferred.resolve()
      
      Account.fetch()
      
      $.when(
        accountDeferred
      ).done =>
        @navigation.render()
        callback?()
      
      @
