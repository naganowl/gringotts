import jQuery from 'jquery'
window.$ = window.jQuery = jQuery

import chai from 'chai'
chai.use require('sinon-chai')
chai.use require('chai-jquery')
window.expect = chai.expect

require 'bootstrap/js/button'
require 'bootstrap/js/collapse'
require 'bootstrap/js/dropdown'
require 'bootstrap/js/modal'
require 'bootstrap/js/tab'
require 'bootstrap/js/tooltip'
require 'bootstrap/js/transition'

testContext = require.context '../', true, /\.spec\.coffee$/
testContext.keys().forEach testContext
