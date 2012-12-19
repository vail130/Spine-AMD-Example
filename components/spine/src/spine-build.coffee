Events =
  bind: (ev, callback) ->
    evs   = ev.split(' ')
    calls = @hasOwnProperty('_callbacks') and @_callbacks or= {}

    for name in evs
      calls[name] or= []
      calls[name].push(callback)
    this

  one: (ev, callback) ->
    @bind ev, ->
      @unbind(ev, arguments.callee)
      callback.apply(this, arguments)

  trigger: (args...) ->
    ev = args.shift()

    list = @hasOwnProperty('_callbacks') and @_callbacks?[ev]
    return unless list

    for callback in list
      if callback.apply(this, args) is false
        break
    true

  unbind: (ev, callback) ->
    unless ev
      @_callbacks = {}
      return this

    list = @_callbacks?[ev]
    return this unless list

    unless callback
      delete @_callbacks[ev]
      return this

    for cb, i in list when cb is callback
      list = list.slice()
      list.splice(i, 1)
      @_callbacks[ev] = list
      break
    this

Log =
  trace: true

  logPrefix: '(App)'

  log: (args...) ->
    return unless @trace
    if @logPrefix then args.unshift(@logPrefix)
    console?.log?(args...)
    this

moduleKeywords = ['included', 'extended']

class Module
  @include: (obj) ->
    throw new Error('include(obj) requires obj') unless obj
    for key, value of obj when key not in moduleKeywords
      @::[key] = value
    obj.included?.apply(this)
    this

  @extend: (obj) ->
    throw new Error('extend(obj) requires obj') unless obj
    for key, value of obj when key not in moduleKeywords
      @[key] = value
    obj.extended?.apply(this)
    this

  @proxy: (func) ->
    => func.apply(this, arguments)

  proxy: (func) ->
    => func.apply(this, arguments)

  constructor: ->
    @init?(arguments...)

class Model extends Module
  @extend Events

  @records: {}
  @crecords: {}
  @attributes: []

  @configure: (name, attributes...) ->
    @className  = name
    @records    = {}
    @crecords   = {}
    @attributes = attributes if attributes.length
    @attributes and= makeArray(@attributes)
    @attributes or=  []
    @unbind()
    this

  @toString: -> "#{@className}(#{@attributes.join(", ")})"

  @find: (id) ->
    record = @records[id]
    if !record and ("#{id}").match(/c-\d+/)
      return @findCID(id)
    throw new Error('Unknown record') unless record
    record.clone()

  @findCID: (cid) ->
    record = @crecords[cid]
    throw new Error('Unknown record') unless record
    record.clone()

  @exists: (id) ->
    try
      return @find(id)
    catch e
      return false

  @refresh: (values, options = {}) ->
    if options.clear
      @records  = {}
      @crecords = {}

    records = @fromJSON(values)
    records = [records] unless isArray(records)

    for record in records
      record.id           or= record.cid
      @records[record.id]   = record
      @crecords[record.cid] = record

    @trigger('refresh', @cloneArray(records))
    this

  @select: (callback) ->
    result = (record for id, record of @records when callback(record))
    @cloneArray(result)

  @findByAttribute: (name, value) ->
    for id, record of @records
      if record[name] is value
        return record.clone()
    null

  @findAllByAttribute: (name, value) ->
    @select (item) ->
      item[name] is value

  @each: (callback) ->
    for key, value of @records
      callback(value.clone())

  @all: ->
    @cloneArray(@recordsValues())

  @first: ->
    record = @recordsValues()[0]
    record?.clone()

  @last: ->
    values = @recordsValues()
    record = values[values.length - 1]
    record?.clone()

  @count: ->
    @recordsValues().length

  @deleteAll: ->
    for key, value of @records
      delete @records[key]

  @destroyAll: ->
    for key, value of @records
      @records[key].destroy()

  @update: (id, atts, options) ->
    @find(id).updateAttributes(atts, options)

  @create: (atts, options) ->
    record = new @(atts)
    record.save(options)

  @destroy: (id, options) ->
    @find(id).destroy(options)

  @change: (callbackOrParams) ->
    if typeof callbackOrParams is 'function'
      @bind('change', callbackOrParams)
    else
      @trigger('change', callbackOrParams)

  @fetch: (callbackOrParams) ->
    if typeof callbackOrParams is 'function'
      @bind('fetch', callbackOrParams)
    else
      @trigger('fetch', callbackOrParams)

  @toJSON: ->
    @recordsValues()

  @fromJSON: (objects) ->
    return unless objects
    if typeof objects is 'string'
      objects = JSON.parse(objects)
    if isArray(objects)
      (new @(value) for value in objects)
    else
      new @(objects)

  @fromForm: ->
    (new this).fromForm(arguments...)

  # Private

  @recordsValues: ->
    result = []
    for key, value of @records
      result.push(value)
    result

  @cloneArray: (array) ->
    (value.clone() for value in array)

  @idCounter: 0

  @uid: (prefix = '') ->
    uid = prefix + @idCounter++
    uid = @uid(prefix) if @exists(uid)
    uid

  # Instance

  constructor: (atts) ->
    super
    @load atts if atts
    @cid = @constructor.uid('c-')

  isNew: ->
    not @exists()

  isValid: ->
    not @validate()

  validate: ->

  load: (atts) ->
    for key, value of atts
      if typeof @[key] is 'function'
        @[key](value)
      else
        @[key] = value
    this

  attributes: ->
    result = {}
    for key in @constructor.attributes when key of this
      if typeof @[key] is 'function'
        result[key] = @[key]()
      else
        result[key] = @[key]
    result.id = @id if @id
    result

  eql: (rec) ->
    !!(rec and rec.constructor is @constructor and
        (rec.cid is @cid) or (rec.id and rec.id is @id))

  save: (options = {}) ->
    unless options.validate is false
      error = @validate()
      if error
        @trigger('error', error)
        return false

    @trigger('beforeSave', options)
    record = if @isNew() then @create(options) else @update(options)
    @trigger('save', options)
    record

  updateAttribute: (name, value, options) ->
    @[name] = value
    @save(options)

  updateAttributes: (atts, options) ->
    @load(atts)
    @save(options)

  changeID: (id) ->
    records = @constructor.records
    records[id] = records[@id]
    delete records[@id]
    @id = id
    @save()

  destroy: (options = {}) ->
    @trigger('beforeDestroy', options)
    delete @constructor.records[@id]
    delete @constructor.crecords[@cid]
    @destroyed = true
    @trigger('destroy', options)
    @trigger('change', 'destroy', options)
    @unbind()
    this

  dup: (newRecord) ->
    result = new @constructor(@attributes())
    if newRecord is false
      result.cid = @cid
    else
      delete result.id
    result

  clone: ->
    createObject(this)

  reload: ->
    return this if @isNew()
    original = @constructor.find(@id)
    @load(original.attributes())
    original

  toJSON: ->
    @attributes()

  toString: ->
    "<#{@constructor.className} (#{JSON.stringify(this)})>"

  fromForm: (form) ->
    result = {}
    for key in $(form).serializeArray()
      result[key.name] = key.value
    @load(result)

  exists: ->
    @id && @id of @constructor.records

  # Private

  update: (options) ->
    @trigger('beforeUpdate', options)
    records = @constructor.records
    records[@id].load @attributes()
    clone = records[@id].clone()
    clone.trigger('update', options)
    clone.trigger('change', 'update', options)
    clone

  create: (options) ->
    @trigger('beforeCreate', options)
    @id          = @cid unless @id

    record       = @dup(false)
    @constructor.records[@id]   = record
    @constructor.crecords[@cid] = record

    clone        = record.clone()
    clone.trigger('create', options)
    clone.trigger('change', 'create', options)
    clone

  bind: (events, callback) ->
    @constructor.bind events, binder = (record) =>
      if record && @eql(record)
        callback.apply(this, arguments)
    @constructor.bind 'unbind', unbinder = (record) =>
      if record && @eql(record)
        @constructor.unbind(events, binder)
        @constructor.unbind('unbind', unbinder)
    binder

  one: (events, callback) ->
    binder = @bind events, =>
      @constructor.unbind(events, binder)
      callback.apply(this, arguments)

  trigger: (args...) ->
    args.splice(1, 0, this)
    @constructor.trigger(args...)

  unbind: ->
    @trigger('unbind')

class Controller extends Module
  @include Events
  @include Log

  eventSplitter: /^(\S+)\s*(.*)$/
  tag: 'div'

  constructor: (options) ->
    @options = options

    for key, value of @options
      @[key] = value

    @el  = document.createElement(@tag) unless @el
    @el  = $(@el)
    @$el = @el

    @el.addClass(@className) if @className
    @el.attr(@attributes) if @attributes

    @events = @constructor.events unless @events
    @elements = @constructor.elements unless @elements

    @delegateEvents(@events) if @events
    @refreshElements() if @elements

    super

  release: =>
    @trigger 'release'
    @el.remove()
    @unbind()

  $: (selector) -> $(selector, @el)

  delegateEvents: (events) ->
    for key, method of events

      if typeof(method) is 'function'
        # Always return true from event handlers
        method = do (method) => =>
          method.apply(this, arguments)
          true
      else
        unless @[method]
          throw new Error("#{method} doesn't exist")

        method = do (method) => =>
          @[method].apply(this, arguments)
          true

      match      = key.match(@eventSplitter)
      eventName  = match[1]
      selector   = match[2]

      if selector is ''
        @el.bind(eventName, method)
      else
        @el.delegate(selector, eventName, method)

  refreshElements: ->
    for key, value of @elements
      @[value] = @$(key)

  delay: (func, timeout) ->
    setTimeout(@proxy(func), timeout || 0)

  html: (element) ->
    @el.html(element.el or element)
    @refreshElements()
    @el

  append: (elements...) ->
    elements = (e.el or e for e in elements)
    @el.append(elements...)
    @refreshElements()
    @el

  appendTo: (element) ->
    @el.appendTo(element.el or element)
    @refreshElements()
    @el

  prepend: (elements...) ->
    elements = (e.el or e for e in elements)
    @el.prepend(elements...)
    @refreshElements()
    @el

  replace: (element) ->
    [previous, @el] = [@el, $(element.el or element)]
    previous.replaceWith(@el)
    @delegateEvents(@events)
    @refreshElements()
    @el

# Utilities & Shims

$ = window?.jQuery or window?.Zepto or (element) -> element

createObject = Object.create or (o) ->
  Func = ->
  Func.prototype = o
  new Func()

isArray = (value) ->
  Object::toString.call(value) is '[object Array]'

isBlank = (value) ->
  return true unless value
  return false for key of value
  true

makeArray = (args) ->
  Array::slice.call(args, 0)

# Globals

Spine = @Spine   = {}
module?.exports  = Spine

Spine.version    = '1.0.8'
Spine.isArray    = isArray
Spine.isBlank    = isBlank
Spine.$          = $
Spine.Events     = Events
Spine.Log        = Log
Spine.Module     = Module
Spine.Controller = Controller
Spine.Model      = Model

# Global events

Module.extend.call(Spine, Events)

# JavaScript compatability

Module.create = Module.sub =
  Controller.create = Controller.sub =
    Model.sub = (instances, statics) ->
      class result extends this
      result.include(instances) if instances
      result.extend(statics) if statics
      result.unbind?()
      result

Model.setup = (name, attributes = []) ->
  class Instance extends this
  Instance.configure(name, attributes...)
  Instance

Spine.Class = ModuleSpine  = @Spine or require('spine')
$      = Spine.$

class Spine.List extends Spine.Controller
  events:
    'click .item': 'click'

  selectFirst: false

  constructor: ->
    super
    @bind 'change', @change

  template: ->
    throw 'Override template'

  change: (item) =>
    @current = item

    unless @current
      @children().removeClass('active')
      return

    @children().removeClass('active')
    $(@children().get(@items.indexOf(@current))).addClass('active')

  render: (items) ->
    @items = items if items
    @html @template(@items)
    @change @current
    if @selectFirst
      unless @children('.active').length
        @children(':first').click()

  children: (sel) ->
    @el.children(sel)

  click: (e) ->
    item = @items[$(e.currentTarget).index()]
    @trigger('change', item)
    true

module?.exports = Spine.ListSpine  = @Spine or require('spine')
$      = Spine.$

class Spine.Manager extends Spine.Module
  @include Spine.Events

  constructor: ->
    @controllers = []
    @bind 'change', @change
    @add(arguments...)

  add: (controllers...) ->
    @addOne(cont) for cont in controllers

  addOne: (controller) ->
    controller.bind 'active', (args...) =>
      @trigger('change', controller, args...)
    controller.bind 'release', =>
      @controllers.splice(@controllers.indexOf(controller), 1)

    @controllers.push(controller)

  deactivate: ->
    @trigger('change', false, arguments...)

  # Private

  change: (current, args...) ->
    for cont in @controllers
      if cont is current
        cont.activate(args...)
      else
        cont.deactivate(args...)

Spine.Controller.include
  active: (args...) ->
    if typeof args[0] is 'function'
      @bind('active', args[0])
    else
      args.unshift('active')
      @trigger(args...)
    @

  isActive: ->
    @el.hasClass('active')

  activate: ->
    @el.addClass('active')
    @

  deactivate: ->
    @el.removeClass('active')
    @

class Spine.Stack extends Spine.Controller
  controllers: {}
  routes: {}

  className: 'spine stack'

  constructor: ->
    super

    @manager = new Spine.Manager

    for key, value of @controllers
      @[key] = new value(stack: @)
      @add(@[key])

    for key, value of @routes
      do (key, value) =>
        callback = value if typeof value is 'function'
        callback or= => @[value].active(arguments...)
        @route(key, callback)

    @[@default].active() if @default

  add: (controller) ->
    @manager.add(controller)
    @append(controller)

module?.exports = Spine.Manager
module?.exports.Stack = Spine.StackSpine = @Spine or require('spine')
$     = Spine.$

hashStrip    = /^#*/
namedParam   = /:([\w\d]+)/g
splatParam   = /\*([\w\d]+)/g
escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g

class Spine.Route extends Spine.Module
  @extend Spine.Events

  @historySupport: window.history?.pushState?

  @routes: []

  @options:
    trigger: true
    history: false
    shim: false

  @add: (path, callback) ->
    if (typeof path is 'object' and path not instanceof RegExp)
      @add(key, value) for key, value of path
    else
      @routes.push(new @(path, callback))

  @setup: (options = {}) ->
    @options = $.extend({}, @options, options)

    if (@options.history)
      @history = @historySupport && @options.history

    return if @options.shim

    if @history
      $(window).bind('popstate', @change)
    else
      $(window).bind('hashchange', @change)
    @change()

  @unbind: ->
    if @history
      $(window).unbind('popstate', @change)
    else
      $(window).unbind('hashchange', @change)

  @navigate: (args...) ->
    options = {}

    lastArg = args[args.length - 1]
    if typeof lastArg is 'object'
      options = args.pop()
    else if typeof lastArg is 'boolean'
      options.trigger = args.pop()

    options = $.extend({}, @options, options)

    path = args.join('/')
    return if @path is path
    @path = path

    @trigger('navigate', @path)

    @matchRoute(@path, options) if options.trigger

    return if options.shim

    if @history
      history.pushState(
        {},
        document.title,
        @path
      )
    else
      window.location.hash = @path

  # Private

  @getPath: ->
    path = window.location.pathname
    if path.substr(0,1) isnt '/'
      path = '/' + path
    path

  @getHash: -> window.location.hash

  @getFragment: -> @getHash().replace(hashStrip, '')

  @getHost: ->
    (document.location + '').replace(@getPath() + @getHash(), '')

  @change: ->
    path = if @getFragment() isnt '' then @getFragment() else @getPath()
    return if path is @path
    @path = path
    @matchRoute(@path)

  @matchRoute: (path, options) ->
    for route in @routes
      if route.match(path, options)
        @trigger('change', route, path)
        return route

  constructor: (@path, @callback) ->
    @names = []

    if typeof path is 'string'
      namedParam.lastIndex = 0
      while (match = namedParam.exec(path)) != null
        @names.push(match[1])

      splatParam.lastIndex = 0
      while (match = splatParam.exec(path)) != null
        @names.push(match[1])

      path = path.replace(escapeRegExp, '\\$&')
                 .replace(namedParam, '([^\/]*)')
                 .replace(splatParam, '(.*?)')

      @route = new RegExp('^' + path + '$')
    else
      @route = path

  match: (path, options = {}) ->
    match = @route.exec(path)
    return false unless match
    options.match = match
    params = match.slice(1)

    if @names.length
      for param, i in params
        options[@names[i]] = param

    @callback.call(null, options) isnt false

# Coffee-script bug
Spine.Route.change = Spine.Route.proxy(Spine.Route.change)

Spine.Controller.include
  route: (path, callback) ->
    Spine.Route.add(path, @proxy(callback))

  routes: (routes) ->
    @route(key, value) for key, value of routes

  navigate: ->
    Spine.Route.navigate.apply(Spine.Route, arguments)

module?.exports = Spine.RouteSpine   = @Spine or require('spine')
isArray = Spine.isArray
require = @require or ((value) -> eval(value))

class Collection extends Spine.Module
  constructor: (options = {}) ->
    for key, value of options
      @[key] = value

  all: ->
    @model.select (rec) => @associated(rec)

  first: ->
    @all()[0]

  last: ->
    values = @all()
    values[values.length - 1]

  find: (id) ->
    records = @select (rec) =>
      rec.id + '' is id + ''
    throw('Unknown record') unless records[0]
    records[0]

  findAllByAttribute: (name, value) ->
    @model.select (rec) =>
      @associated(rec) and rec[name] is value

  findByAttribute: (name, value) ->
    @findAllByAttribute(name, value)[0]

  select: (cb) ->
    @model.select (rec) =>
      @associated(rec) and cb(rec)

  refresh: (values) ->
    delete @model.records[record.id] for record in @all()
    records = @model.fromJSON(values)

    records = [records] unless isArray(records)

    for record in records
      record.newRecord = false
      record[@fkey] = @record.id
      @model.records[record.id] = record

    @model.trigger('refresh', @model.cloneArray(records))

  create: (record) ->
    record[@fkey] = @record.id
    @model.create(record)

  # Private

  associated: (record) ->
    record[@fkey] is @record.id

class Instance extends Spine.Module
  constructor: (options = {}) ->
    for key, value of options
      @[key] = value

  exists: ->
    @record[@fkey] and @model.exists(@record[@fkey])

  update: (value) ->
    unless value instanceof @model
      value = new @model(value)
    value.save() if value.isNew()
    @record[@fkey] = value and value.id

class Singleton extends Spine.Module
  constructor: (options = {}) ->
    for key, value of options
      @[key] = value

  find: ->
    @record.id and @model.findByAttribute(@fkey, @record.id)

  update: (value) ->
    unless value instanceof @model
      value = @model.fromJSON(value)

    value[@fkey] = @record.id
    value.save()

singularize = (str) ->
  str.replace(/s$/, '')

underscore = (str) ->
  str.replace(/::/g, '/')
     .replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')
     .replace(/([a-z\d])([A-Z])/g, '$1_$2')
     .replace(/-/g, '_')
     .toLowerCase()

Spine.Model.extend
  hasMany: (name, model, fkey) ->
    fkey ?= "#{underscore(this.className)}_id"

    association = (record) ->
      model = require(model) if typeof model is 'string'

      new Collection(
        name: name, model: model,
        record: record, fkey: fkey
      )

    @::[name] = (value) ->
      association(@).refresh(value) if value?
      association(@)

  belongsTo: (name, model, fkey) ->
    fkey ?= "#{singularize(name)}_id"

    association = (record) ->
      model = require(model) if typeof model is 'string'

      new Instance(
        name: name, model: model,
        record: record, fkey: fkey
      )

    @::[name] = (value) ->
      association(@).update(value) if value?
      association(@).exists()

    @attributes.push(fkey)

  hasOne: (name, model, fkey) ->
    fkey ?= "#{underscore(@className)}_id"

    association = (record) ->
      model = require(model) if typeof model is 'string'

      new Singleton(
        name: name, model: model,
        record: record, fkey: fkey
      )

    @::[name] = (value) ->
      association(@).update(value) if value?
      association(@).find()Spine  = @Spine or require('spine')
$      = Spine.$
Model  = Spine.Model

Ajax =
  getURL: (object) ->
    object and object.url?() or object.url

  enabled:  true
  pending:  false
  requests: []

  disable: (callback) ->
    if @enabled
      @enabled = false
      try
        do callback
      catch e
        throw e
      finally
        @enabled = true
    else
      do callback

  requestNext: ->
    next = @requests.shift()
    if next
      @request(next)
    else
      @pending = false

  request: (callback) ->
    (do callback).complete(=> do @requestNext)

  queue: (callback) ->
    return unless @enabled
    if @pending
      @requests.push(callback)
    else
      @pending = true
      @request(callback)
    callback

class Base
  defaults:
    contentType: 'application/json'
    dataType: 'json'
    processData: false
    headers: {'X-Requested-With': 'XMLHttpRequest'}

  ajax: (params, defaults) ->
    $.ajax($.extend({}, @defaults, defaults, params))

  queue: (callback) ->
    Ajax.queue(callback)

class Collection extends Base
  constructor: (@model) ->

  find: (id, params) ->
    record = new @model(id: id)
    @ajax(
      params,
      type: 'GET',
      url:  Ajax.getURL(record)
    ).success(@recordsResponse)
     .error(@errorResponse)

  all: (params) ->
    @ajax(
      params,
      type: 'GET',
      url:  Ajax.getURL(@model)
    ).success(@recordsResponse)
     .error(@errorResponse)

  fetch: (params = {}, options = {}) ->
    if id = params.id
      delete params.id
      @find(id, params).success (record) =>
        @model.refresh(record, options)
    else
      @all(params).success (records) =>
        @model.refresh(records, options)

  # Private

  recordsResponse: (data, status, xhr) =>
    @model.trigger('ajaxSuccess', null, status, xhr)

  errorResponse: (xhr, statusText, error) =>
    @model.trigger('ajaxError', null, xhr, statusText, error)

class Singleton extends Base
  constructor: (@record) ->
    @model = @record.constructor

  reload: (params, options) ->
    @queue =>
      @ajax(
        params,
        type: 'GET'
        url:  Ajax.getURL(@record)
      ).success(@recordResponse(options))
       .error(@errorResponse(options))

  create: (params, options) ->
    @queue =>
      @ajax(
        params,
        type: 'POST'
        data: JSON.stringify(@record)
        url:  Ajax.getURL(@model)
      ).success(@recordResponse(options))
       .error(@errorResponse(options))

  update: (params, options) ->
    @queue =>
      @ajax(
        params,
        type: 'PUT'
        data: JSON.stringify(@record)
        url:  Ajax.getURL(@record)
      ).success(@recordResponse(options))
       .error(@errorResponse(options))

  destroy: (params, options) ->
    @queue =>
      @ajax(
        params,
        type: 'DELETE'
        url:  Ajax.getURL(@record)
      ).success(@recordResponse(options))
       .error(@errorResponse(options))

  # Private

  recordResponse: (options = {}) =>
    (data, status, xhr) =>
      if Spine.isBlank(data)
        data = false
      else
        data = @model.fromJSON(data)

      Ajax.disable =>
        if data
          # ID change, need to do some shifting
          if data.id and @record.id isnt data.id
            @record.changeID(data.id)

          # Update with latest data
          @record.updateAttributes(data.attributes())

      @record.trigger('ajaxSuccess', data, status, xhr)
      options.success?.apply(@record)

  errorResponse: (options = {}) =>
    (xhr, statusText, error) =>
      @record.trigger('ajaxError', xhr, statusText, error)
      options.error?.apply(@record)

# Ajax endpoint
Model.host = ''

Include =
  ajax: -> new Singleton(this)

  url: (args...) ->
    url = Ajax.getURL(@constructor)
    url += '/' unless url.charAt(url.length - 1) is '/'
    url += encodeURIComponent(@id)
    args.unshift(url)
    args.join('/')

Extend =
  ajax: -> new Collection(this)

  url: (args...) ->
    args.unshift(@className.toLowerCase() + 's')
    args.unshift(Model.host)
    args.join('/')

Model.Ajax =
  extended: ->
    @fetch @ajaxFetch
    @change @ajaxChange

    @extend Extend
    @include Include

  # Private

  ajaxFetch: ->
    @ajax().fetch(arguments...)

  ajaxChange: (record, type, options = {}) ->
    return if options.ajax is false
    record.ajax()[type](options.ajax, options)

Model.Ajax.Methods =
  extended: ->
    @extend Extend
    @include Include

# Globals
Ajax.defaults   = Base::defaults
Spine.Ajax      = Ajax
module?.exports = AjaxSpine = @Spine or require('spine')

Spine.Model.Local =
  extended: ->
    @change @saveLocal
    @fetch @loadLocal

  saveLocal: ->
    result = JSON.stringify(@)
    localStorage[@className] = result

  loadLocal: ->
    result = localStorage[@className]
    @refresh(result or [], clear: true)

module?.exports = Spine.Model.Local