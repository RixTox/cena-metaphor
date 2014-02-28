express    = require 'express'
path       = require 'path'

###*
 * Middleware Configurator
 * @param  {Express App} app
 * @return {null}
###
module.exports = (app) ->
  app.use express.logger 'dev'
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.methodOverride()
  app.use require('./compiler') app
  app.use express.static path.join app.get('client-path'), 'static'
  app.use express.favicon path.join app.get('client-path'), 'static/favicon.ico'
  app.use require './slash'
  app.use app.router
  app.use require(path.join app.get('server-path'), 'routes/http').http500