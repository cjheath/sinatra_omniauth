# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "sinatra_omniauth"
  gem.homepage = "http://github.com/cjheath/sinatra_omniauth"
  gem.license = "MIT"
  gem.summary = %Q{A Sinatra extension that provides pure OmniAuth goodness to your application (with DataMapper)}
  gem.description = %Q{This Sinatra extension, derived from omniauth_pure by Marcus Proske, adds OmniAuth authorization to your Sinatra application, so your users can login using FaceBook, Twitter and many other authorization providers, as long as you supply the API keys. It uses DataMapper and HAML.}
  gem.email = "clifford.heath@gmail.com"
  gem.authors = ["Clifford Heath"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "sinatra_omniauth #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
