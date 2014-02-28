path = require 'path'
express = require 'express'

module.exports = (app, config) ->
  # Add configuration to app
  for key, val of config
    app.set key, val

  # Configure environments
  app.configure ->
    app.set 'views', path.join app.get('client-path'), 'views'
  app.configure 'development', ->
    console.log 'Development Environment'
    app.enable 'force compile'
    app.disable 'compress'
    app.locals.pretty = true
    app.use express.errorHandler()
  app.configure 'production', ->
    app.disable 'force compile'
    app.enable 'compress' 

  # Set locals
  app.locals.app = app
