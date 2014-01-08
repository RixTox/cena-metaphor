fs = require 'fs'
path = require 'path'
extname = path.extname
dirname = path.dirname
resolve = path.resolve
exists = fs.exists
statSync = fs.statSync
existsSync = fs.existsSync
readdirSync = fs.readdirSync

default_options_list = ['path_base', 'mode']
accept_extname = ['.coffee', '.js', '.json']

default_options =
  path_base: '/'
  mode: 'independent'

object_filter = (obj, arr) ->
  ret = {}
  for i in arr
    unless typeof obj[i] == 'undefined'
      ret[i] = obj[i]
  return ret

apply_default_options = (options, default_options) ->
  for k, v of default_options
    if typeof options[k] == 'undefined'
      options[k] = v

get_file_dir_list = (path) ->
  list =
    dir: []
    file: []
  for file in readdirSync path
    file = resolve path, file
    if statSync(file).isDirectory()
      list.dir.push file
    else
      list.file.push file
  return list

decide_loader = (options) ->
  console.log options
  switch options.mode
    when 'independent'
      return independent_loader
    when 'dependent'
      return dependent_loader

try_require = (path) ->
  try
    ret = require path
  catch error
    console.log "Error when loading #{path}:\n", error
    process.exit 1
  return ret

independent_loader = (options) ->
  ret = []
  for path in options.file_dir_list.file
    if extname(path).toLowerCase() in accept_extname
      ret.push try_require path
  for path in options.file_dir_list.dir
    ret.push try_require path
  return ret

dependent_loader = (options) ->

###*
 * Module Loader
 * @param {Object}   options Options passed to loader
 * ------OR------
 * @param {String}   path    Absolute path to load
 * ------OR------
 * @param {String}   path    Relative path to load
 * @param {String}   base    Base path to resolve
###
Loader = (options, base) ->
  if typeof options == 'string'
    options = path: options
    if typeof base == 'string'
      options.path_base = base
  apply_default_options options, default_options
  options.path = resolve options.path_base, options.path
  options.file_dir_list = get_file_dir_list options.path
  loader = decide_loader options
  return loader options

Loader.default = (options) ->
  if options?
    options = object_filter options, default_options_list
    for k, v of options
      default_options[k] = v
  return default_options

module.exports = Loader
