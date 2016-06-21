GlobChanges = require './lib/GlobChanges'

globChanges = ( args... ) ->
  new GlobChanges().changes args...

globChanges.GlobChanges = GlobChanges

module.exports = globChanges