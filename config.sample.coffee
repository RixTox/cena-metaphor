path = require 'path'

module.exports =
  'port'              : process.env.PORT or 3000
  'app-path'          : __dirname
  'client-path'       : path.join __dirname, 'client'
  'server-path'       : path.join __dirname, 'server'
  'base'              : '/'
  'view engine'       : 'jade'
  'x-powered-by'      : false
  'strict routing'    : true