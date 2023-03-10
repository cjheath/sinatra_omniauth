# -*- encoding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name = "sinatra_omniauth"
  spec.version = "1.3.0"
  spec.authors = ["Clifford Heath"]
  spec.email = "clifford.heath@gmail.com"

  spec.date = "2023-03-11"
  spec.summary = "A Sinatra extension that provides pure OmniAuth goodness to your application (with DataMapper)"
  spec.description = "This Sinatra extension, derived from omniauth_pure by Marcus Proske, adds OmniAuth authorization to your Sinatra application, so your users can login using FaceBook, Twitter and many other authorization providers, as long as you supply the API keys. It uses DataMapper and HAML."
  spec.homepage = "http://github.com/cjheath/sinatra_omniauth"
  spec.licenses = ["MIT"]
  spec.require_paths = ["lib"]

  spec.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]

  spec.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "config.ru",
    "css/auth.css",
    "images/authbuttons/aol_128.png",
    "images/authbuttons/aol_256.png",
    "images/authbuttons/aol_32.png",
    "images/authbuttons/aol_64.png",
    "images/authbuttons/basecamp_128.png",
    "images/authbuttons/basecamp_256.png",
    "images/authbuttons/basecamp_32.png",
    "images/authbuttons/basecamp_64.png",
    "images/authbuttons/campfire_128.png",
    "images/authbuttons/campfire_256.png",
    "images/authbuttons/campfire_32.png",
    "images/authbuttons/campfire_64.png",
    "images/authbuttons/facebook_128.png",
    "images/authbuttons/facebook_256.png",
    "images/authbuttons/facebook_32.png",
    "images/authbuttons/facebook_64.png",
    "images/authbuttons/github_128.png",
    "images/authbuttons/github_256.png",
    "images/authbuttons/github_32.png",
    "images/authbuttons/github_64.png",
    "images/authbuttons/google_128.png",
    "images/authbuttons/google_256.png",
    "images/authbuttons/google_32.png",
    "images/authbuttons/google_64.png",
    "images/authbuttons/linkedin_128.png",
    "images/authbuttons/linkedin_256.png",
    "images/authbuttons/linkedin_32.png",
    "images/authbuttons/linkedin_64.png",
    "images/authbuttons/myspace_128.png",
    "images/authbuttons/myspace_256.png",
    "images/authbuttons/myspace_32.png",
    "images/authbuttons/myspace_64.png",
    "images/authbuttons/openid_128.png",
    "images/authbuttons/openid_256.png",
    "images/authbuttons/openid_32.png",
    "images/authbuttons/openid_64.png",
    "images/authbuttons/presently_128.png",
    "images/authbuttons/presently_256.png",
    "images/authbuttons/presently_32.png",
    "images/authbuttons/presently_64.png",
    "images/authbuttons/twitter_128.png",
    "images/authbuttons/twitter_256.png",
    "images/authbuttons/twitter_32.png",
    "images/authbuttons/twitter_64.png",
    "images/authbuttons/yahoo_128.png",
    "images/authbuttons/yahoo_256.png",
    "images/authbuttons/yahoo_32.png",
    "images/authbuttons/yahoo_64.png",
    "lib/sinatra/omniauth.rb",
    "models/authentication.rb",
    "models/user.rb",
    "omniauth.yml",
    "sinatra_omniauth.gemspec",
    "test/helper.rb",
    "test/test_sinatra_omniauth.rb",
    "views/auth.haml"
  ]

  spec.add_runtime_dependency(%q<sinatra>, [">= 0"])
  spec.add_runtime_dependency(%q<omniauth>, [">= 0"])
  spec.add_runtime_dependency(%q<omniauth-twitter>, [">= 0"])
  spec.add_runtime_dependency(%q<dm-core>, [">= 0"])
  spec.add_runtime_dependency(%q<addressable>, [">= 0"])
  spec.add_runtime_dependency(%q<dm-migrations>, [">= 0"])
  spec.add_runtime_dependency(%q<dm-postgres-adapter>, [">= 0"])
  spec.add_runtime_dependency(%q<sqlite3>, [">= 0"])
  spec.add_runtime_dependency(%q<rack-flash3>, [">= 0"])
  spec.add_runtime_dependency(%q<uuidtools>, [">= 0"])
  spec.add_runtime_dependency(%q<haml>, [">= 3.1.1"])

  spec.add_development_dependency(%q<bundler>, [">= 1.0.0"])
  spec.add_development_dependency(%q<rcov>, ["~> 0.9.11"])
  spec.add_development_dependency(%q<simplecov>, ["~> 0.6.4"])
  spec.add_development_dependency(%q<rdoc>, [">= 2.4.0"])
  spec.add_development_dependency(%q<dm-sqlite-adapter>, [">= 0"])
  spec.add_development_dependency(%q<rspec>, ["~> 3.12"])
  spec.add_development_dependency(%q<rake>, [">= 11"])
end

