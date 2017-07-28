utils = require 'lib/utils'
helper = require '../../lib/mixin-helper'
SafeSyncCallback = require '../../mixins/models/safe-sync-callback'

###*
  * An extensible mixin to intercept Model's syncing operation and adding
  * the required HTTP Headers to the XHR request.
  * @param  {Model|Collection} superclass Any Backbone Model or Collection.
###
module.exports = (superclass) -> helper.apply superclass, (superclass) -> \

class WithHeaders extends SafeSyncCallback superclass
  helper.setTypeName @prototype, 'WithHeaders'

  ###*
    * A few default headers that are assumed to be added
    * to every ajax request.
  ###
  HEADERS:
    'Content-Type': 'application/json'
    'Accept': 'application/json'

  ###*
    * Force passing cookies to ajax requests while in CORS mode.
    * @type {Boolean}
  ###
  withCredentials: true

  initialize: ->
    helper.assertModelOrCollection this
    unless @HEADERS
      throw new Error 'HEADERS is required'
    super

  ###*
    * Resolves headers and extends Backbone options with updated headers hash
    * before syncing the model.
    * @return {Deferred}   A jquery Deferred object.
  ###
  sync: (method, model, options) ->
    $xhr = null
    promise = @resolveHeaders(@HEADERS).then (headers) =>
      $xhr = super method, model, @extendWithHeaders options, headers
    promise.abort = ->
      $xhr?.abort() # compatibility with ajax deferred
      promise
    promise

  ###*
    * Resolves headers actual value. Since headers maybe be a function then
    * invoke it. Result of the function may be a hash of headers or a jquery
    * Deferred instance. Therefore return a new Deferred for
    * a subsequent chaining.
    * @param  {Object|Function|Deferred} headers Some value to resolve
    *                                            headers from.
    * @return {Object|Deferred}            A hash of headers or a Deferred
    *                                      to chain with.
  ###
  resolveHeaders: (headers) ->
    sourceHeaders =
      if _.isFunction headers
      then headers.apply(this) else headers
    utils.disposable $.when(sourceHeaders), => @disposed

  ###*
    * Extends the Backbone ajax options with headers hash object.
  ###
  extendWithHeaders: (options, headers) ->
    _.extend options,
      xhrFields: {@withCredentials}
      headers: _.extend {}, options?.headers, headers
