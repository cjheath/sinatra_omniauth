#!/usr/bin/env ruby
#
# Driver program for Sinatra Omniauth gem.
# You don't need to use this in your program, it just demonstrates the minimum to get things running
#

require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-sqlite-adapter'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/omniauth_sinatra.sqlite3")

DataMapper.auto_upgrade!

app = Sinatra::Omniauth.new

# Set up API keys:
app.settings.set :omniauth, {
  :facebook => []
  # etc...
}

run app
