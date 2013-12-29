async = require 'async'
path = require 'path'

# TODO: add Etag cache support

compilers = [
  require './coffee'
  require './stylus'
]
options = {}
env = public_uri = source_path = dest_path = ''

compiler = (req, res, next) ->
  unless req.path.indexOf public_uri == 0
    return next()
  file_ext = path.extname req.path
  file_uri = req.path.substr public_uri.length
  file_path = path.join source_path, file_uri
  file_dest_path = path.join dest_path, file_uri
  file_base_path = path.join path.dirname(file_path), path.basename(file_path, file_ext)
  async.map compilers, (compiler, callback) ->
    compiler
      uri_ext: file_ext
      file_base_path: file_base_path
      dest_path: file_dest_path
      env: env
      opt: options
      , callback
  , (err, results) ->
    return res.send err if err
    for result in results
      if result.exists
        return result.send res unless result.static
        return next()
    next()

module.exports = (app) ->
  options = app.get 'compilers'
  env = app.get('env') || 'development'
  public_uri = path.resolve app.get('base') || '/'
  source_path = path.join app.get('client-path'), 'src'
  if !source_path
    throw new Error 'Compiler middleware needs source-path in configuration'
  dest_path = path.join app.get('client-path'), 'dest'
  return compiler
