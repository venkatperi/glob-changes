Q = require 'q'
_ = require 'lodash'
CacheSwap = require 'cache-swap'
glob = require 'glob-all'
sha1 = require 'sha1'
moment = require 'moment'
fs = require 'fs'

methods =
  _clear : 'clear'
  has : 'hasCached'
  set : 'addCached'
  get : 'getCached'
  delete : 'removeCached'

statEqual = ( a, b ) ->
  return false unless a.size is b.size
  return false unless moment(a.mtime).isSame moment(b.mtime)
  true

class GlobChanges
  constructor : ( opts = {} ) ->
    @fileCache = opts.fileCache or new CacheSwap()
    @category = opts.category or 'glob'

    for own k,v of methods
      do ( k, v ) =>
        @fileCache[ k ] ?= ( args... ) =>
          Q.nmapply @fileCache, v, [ @category ].concat args...

  clearCache : =>
    @fileCache._clear()

  changes : ( key, patterns, opts ) =>
    _opts = _.extend {}, opts, stat : true
    new Q.promise ( resolve ) ->
      g = glob patterns, _opts, ( err, res ) ->
        info = {}
        missing = []
        for x in res or []
          if g.statCache[ x ]
            info[ x ] = g.statCache[ x ]
          else
            missing.push x

        if missing.length
          throw new Error "Couldn't stat the following: #{missing}"
        resolve info

    .then ( info ) =>
      results = patterns : patterns, opts : opts, files : info
      str = JSON.stringify results

      @fileCache.get key
      .then ( cached )=>
        change =
          added : []
          removed : []
          changed : []
          all : Object.keys info
          
        if cached?
          hash = sha1 str
          oldHash = sha1 cached.contents
          return change if hash is oldHash

        if !cached?
          change.added = Object.keys info
        else
          old = JSON.parse cached.contents
          allFiles = _.union Object.keys(info), Object.keys(old.files)
          for f in allFiles
            a = info[ f ]
            b = old.files[ f ]
            if a and !b
              change.added.push f
            else if !a and b
              change.removed.push f
            else if !statEqual a, b
              change.changed.push f

        @fileCache.set key, str
        .then -> change

module.exports = GlobChanges

