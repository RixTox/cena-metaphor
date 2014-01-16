fs          = require 'fs'
path        = require 'path'
async       = require 'async'
_           = require 'underscore'
stat        = fs.stat
exists      = fs.exists
readdir     = fs.readdir
statSync    = fs.statSync
existsSync  = fs.existsSync
readdirSync = fs.readdirSync
extname     = path.extname
dirname     = path.dirname
resolve     = path.resolve
basename    = path.basename

defaults =
  # Include only directories under path
  dirOnly: off
  # Load mode, include:
  # * independent - require every file and folder directly
  # * dependent   - analyse depencence then load them in order
  mode: 'independent'
  # Return the result as an object or array
  object: on
  # Allow to include the caller file itself
  self: off

getCaller = (offset = 0) ->
  traceFn = Error.prepareStackTrace
  Error.prepareStackTrace = (e, s) -> s
  stack = (new Error()).stack
  Error.prepareStackTrace = traceFn
  return stack[2 - offset].getFileName()

getFilepaths = (options, callback) ->
  filepath = options.path
  errNotFound = new Error "Loader: Cannot find path #{filepath}"
  errFile = new Error "Loader: Loading a file #{filepath}"
  clear = (arr) ->
    arr.filter (item) -> item
  cancatFiles = (filenames, callback) ->
    filepaths = filenames.map (_filepath) ->
      _filepath = resolve filepath, _filepath
      isDir = statSync(_filepath).isDirectory()
      unless !options.dirOnly || isDir
        return undefined
      _filepath += isDir && '/' || ''
    filepaths = filepaths.filter (filepath, index) ->
      unless filepath && (options.self || filepath != options.caller) &&
      (!options.filterSync || options.filterSync filenames[index], filepath)
        return !delete filenames[index]
      return true
    filenames = clear filenames
    return filepaths unless callback
    return callback null, filepaths unless options.filter
    async.map Object.keys(filenames), (index, callback) ->
      options.filter filenames[index]
      , filepaths[index]
      , (err, result) ->
        return callback err if err
        return callback null, result && filepaths[index] || undefined
    , (err, result) ->
      return callback err if err
      return callback null, clear result
  if callback
    return exists filepath, (fileExists) ->
      unless fileExists
        return callback errNotFound
      stat filepath, (err, fileStat) ->
        return callback err if err
        unless fileStat.isDirectory()
          return callback errFile
        readdir filepath, (err, filenames) ->
          return callback err if err
          return cancatFiles filenames, callback
  else
    unless existsSync filepath
      throw errNotFound
    if statSync(filepath).isDirectory()
      return cancatFiles readdirSync filepath
    else throw errFile

decideLoader = (options) ->
  options.loader = switch options.mode
    when 'independent'
      independentLoader
    when 'dependent'
      options.dirOnly = on
      independentLoader

independentLoader = (options, callback) ->
  ret = {}
  for filepath in options.filepaths
    ret[basename filepath] = require filepath
  unless options.object
    ret = Object.keys(ret).map (k) -> ret[k]
  unless callback
    return ret
  return callback null, ret

dependentLoader = (options, callback) ->

###*
 * Module Loader
 * @param {Object}   options
 * ------OR------
 * @param {String}   path
###
Loader = (args, callback) ->
  if typeof args == 'string'
    args = path: args

  options = _.clone args

  # apply default options
  _.defaults options, defaults

  # find the file path of the caller
  options.caller = getCaller()
  unless options.base?
    options.base = dirname options.caller

  # resolve relative path to caller dir
  options.path = resolve options.base, options.path

  # choose loader for different modes
  decideLoader options

  unless callback
    options.filepaths = getFilepaths options
    return options.loader options

  getFilepaths options, (err, filepaths) ->
    return callback err if err
    options.filepaths = filepaths
    options.loader options, callback

###*
 * Get or set default options
 * @param  {Object} options Default options to set
 * @return {Object}         Default options
###
Loader.default = (options) ->
  return defaults unless options
  defaults = _.map defaults, (v, k) ->
    options[k] || v

module.exports = Loader
