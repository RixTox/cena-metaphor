home = require './home'
meal = require './meal'
http = require './http'

module.exports = (app) ->
  app.get '/'     , home
  app.get '/start', meal
  app.get '*'     , http.http404