$ = require 'jquery'
Model = require 'models/base/model'
Artifacts = require 'collections/artifacts'

module.exports = class Column extends Model

  constructor: ->
    super
    @artifacts = new Artifacts()
