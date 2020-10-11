require 'rubygems'
require 'bundler'

Bundler.require

$stdout.sync = true
$stderr.sync = true

require './wither'
run Wither
