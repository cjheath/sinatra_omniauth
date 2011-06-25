#!/usr/bin/env ruby

require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-sqlite-adapter'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/omniauth_sinatra.sqlite3")

DataMapper.auto_upgrade!

