module.exports = (app) ->
  ########################################
  ###     Load Application Modules     ###
  ########################################

  require('./utils') app
  require('./welcome')

  ########################################
  ###   Load Application Middlewares   ###
  ########################################

  require('./middleware') app
