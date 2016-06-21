should = require 'should'
assert = require 'assert'
shell = require 'shelljs'
GlobChanges = require('../index').GlobChanges

dirs = [
  './test/fixtures/dir1'
]

files = [
  './test/fixtures/a.coffee'
  './test/fixtures/b.coffee'
  './test/fixtures/dir1/a.coffee'
]

describe 'globChanges', ->
  globber = undefined
  pattern = './test/fixtures/**/*.coffee'

  before ->
    shell.rm '-rf', './test/fixtures/'
    dirs.forEach ( d ) ->
      shell.mkdir '-p', d
    files.forEach ( f ) ->
      shell.touch f

  beforeEach ->
    globber = new GlobChanges()

  it 'returns entries under "added" for new results', ( done ) ->
    globber.clearCache()
    .then ->
      globber.changes 'fixtures', pattern
    .then ( results ) ->
      assert results
      assert results.added.length > 0
      assert results.removed.length is 0
      assert results.changed.length is 0
      done()
    .fail done

  it 'returns undefined when no changes', ( done ) ->
    globber.clearCache()
    .then ->
      globber.changes 'fixtures', pattern
    .then ( results ) ->
      assert results isnt undefined
      globber.changes 'fixtures', pattern
    .then ( results ) ->
      assert results is undefined
      done()
    .fail done

  it 'returns new files', ( done ) ->
    globber.clearCache()
    .then ->
      globber.changes 'fixtures', pattern
    .then ( results ) ->
      assert results isnt undefined
      globber.changes 'fixtures', pattern
    .then ( results ) ->
      assert results is undefined
      shell.mkdir 'test/fixtures/dir2'
      shell.touch 'test/fixtures/dir2/dir2.coffee'
      globber.changes 'fixtures', pattern
    .then ( results ) ->
      assert results.added.length is 1
      assert results.removed.length is 0
      assert results.changed.length is 0
      done()
    .fail done

