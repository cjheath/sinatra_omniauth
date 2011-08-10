#!/usr/bin/env ruby
#
# Driver program for SinatraOmniAuth gem.
# You don't need to use this in your program, it just demonstrates the minimum to get things running
#

require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-sqlite-adapter'
require 'sinatra/omniauth'
require 'ruby-debug'; Debugger.start

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/omniauth_sinatra.sqlite3")

DataMapper.auto_upgrade!

class SinatraOmniAuthTestApp < Sinatra::Base
  set :public, Dir.getwd
  set :omniauth, YAML.load_file(File.dirname(__FILE__)+"/omniauth.yml")
  enable :sessions

  register SinatraOmniAuth
end

app = SinatraOmniAuthTestApp.new
run app
