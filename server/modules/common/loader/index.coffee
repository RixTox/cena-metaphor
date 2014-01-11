fs          = require 'fs'
path        = require 'path'
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
  mode: 'independent'
  object: on

getCaller = (offset = 0) ->
  traceFn = Error.prepareStackTrace
  Error.prepareStackTrace = (e, s) -> s
  stack = (new Error()).stack
  Error.prepareStackTrace = traceFn
  return stack[2 - offset].getFileName()

getFileList = (options, callback) ->
  _path = options.path
  cancat_files = (files, callback) ->
    files.map (file) ->
      file = resolve _path, file
      file += statSync(file).isDirectory() && '/' || ''
  if callback
    return exists _path, (_exists) ->
      if _exists
        stat _path, (err, _stat) ->
          return callback err if err
          if _stat.isDirectory()
            readdir _path, (err, files) ->
              return callback err if err
              return callback null, cancat_files files
  else
    unless existsSync _path
      throw new Error "Loader: Cannot find #{_path}"
    unless statSync(_path).isDirectory()
      return cancat_files readdirSync _path
  throw new Error 'Loader: Loading a file'

decideLoader = (options) ->
  switch options.mode
    when 'independent'
      return independentLoader
    when 'dependent'
      return dependent_loader

independentLoader = (options, callback) ->
  ret = {}
  for _path in options.fileList
    ret[basename _path] = require _path
  unless options.object
    ret = Object.keys(ret).map (k) -> ret[k]
  unless callback
    return ret
  callback null, ret

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

  # copy the options parameter
  options = __proto__: args

  # find the file path of the caller
  options.caller = getCaller()
  unless options.base?
    options.base = dirname options.caller

  # apply default options
  for k, v of defaults
    options[k] ?= v

  # resolve relative path to caller dir
  options.path = resolve options.base, options.path

  # choose loader for different modes
  options.loader = decideLoader options

  if callback
    return getFileList options, (err, fileList) ->
      return callback err if err
      options.fileList = fileList
      options.loader options, callback
  else
    options.fileList = getFileList options.path
    return options.loader options

###*
 * Get or set default options
 * @param  {Object} options Default options to set
 * @return {Object}         Default options
###
Loader.default = (options) ->
  if options
    for i in Object.keys defaults
      defaults[i] = options[i]
  return defaults

module.exports = Loader
