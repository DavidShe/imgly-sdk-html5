###
  ImglyKit
  Copyright (c) 2013-2014 img.ly
###
Queue        = require "../vendor/queue.coffee"
Utils        = require "../utils.coffee"
EventEmitter = require("events").EventEmitter
class Operation extends EventEmitter
  renderPreview: true

  ###
    @param {ImglyKit} app
    @param {Object} options
  ###
  constructor: (@app, @options = {}) ->
    @cachedImageData = null

    apply = @apply
    @apply = (dataOrPromise) ->
      Queue(dataOrPromise).then (imageData) =>
        apply.call this, imageData

  ###
    @param {CanvasRenderingContext2d} context
  ###
  setContext: (@context) -> return

  ###
    @param {Object} options
  ###
  setOptions: (options) ->
    for key, val of options
      @options[key] = val

    @emit "updateOptions", options

  ###
    Caches the given image data
  ###
  cacheImageData: (imageData) ->
    return unless imageData?
    @cachedImageData = Utils.cloneImageData imageData

  ###
    Invalidates the cached image data so it can be removed from memory
    by the garbage collection
  ###
  invalidateCache: ->
    @cachedImageData = null

  ###
    Checks whether this operation has a cached copy of the image data
  ###
  hasCache: ->
    !!@cachedImageData

  ###
    This applies this operation to the image in the editor. However, it is not
    responsible for storing the result in any way. It receives imageData and
    returns a modified version.
    @param {ImageData} imageData
    @param {Function} callback
    @returns {ImageData}
  ###
  apply: ->
    throw Error "Abstract: Filter#apply"

  buildComposition = (direction, filter, args = []) ->
    self = this
    if filter.prototype instanceof Operation
      filter = new filter @app, args...
    composition = if direction is "pre"
        (imageData) -> self.apply filter.apply(imageData or this)
      else if direction is "post"
        (imageData) -> filter.apply self.apply(imageData or this)
    composition.compose = Operation::compose
    composition.precompose = Operation::precompose
    composition.filter = filter
    composition

  ###
    @param {Operation} filter
    @returns {Function}
  ###
  compose: (filter, args...) ->
    buildComposition.call this, "post", filter, args

  ###
    @param {Operation} filter
    @returns {Function}
  ###
  precompose: (filter, args...) ->
    buildComposition.call this, "pre", filter, args

module.exports = Operation
