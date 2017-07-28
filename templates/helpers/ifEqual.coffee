utils = require 'lib/utils'

###*
  * Compares two values and renders matching template like #if
###
module.exports = (lvalue, rvalue, options) ->
  if arguments.length < 2
    throw new Error('Handlebars Helper equal needs 2 parameters')
  {fn, inverse} = utils.getHandlebarsFuncs [options or {}]
  if lvalue is rvalue
    if fn then fn this else true
  else if inverse then inverse this else false
