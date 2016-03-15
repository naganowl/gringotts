define (require) ->
  Chaplin = require 'chaplin'
  advice = require '../../mixins/advice'
  activeSyncMachine = require '../../mixins/active-sync-machine'
  overrideXHR = require '../../mixins/override-xhr'
  safeSyncCallback = require '../../mixins/safe-sync-callback'

  # Generic base class for models. Includes useful mixins by default.
  class Model extends Chaplin.Model
    _.extend @prototype, activeSyncMachine, safeSyncCallback, overrideXHR
    advice.call @prototype

    initialize: ->
      super
      @activateSyncMachine()

    sync: ->
      @safeSyncCallback.apply this, arguments
      @safeDeferred super

    fetch: ->
      @overrideXHR super
