load = require './'
load.default path_base: __dirname
modules = load 'test'
console.log modules