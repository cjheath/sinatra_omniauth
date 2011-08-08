#
# Sinatra OmniAuth
#
# Copyright 2011 Clifford Heath.
# License: MIT
#
#   Sinatra OmniAuth provides a Sinatra extension for adding pure OmniAuth authentication
#   to your Sinatra application. "Pure" here means that you don't even need a username
#   on the system, let alone a password; you just sign in using one of your existing
#   social media accounts.
#
#   SinatraOmniAuth uses DataMapper and Haml, though you can write your own templates too.
#   SinatraOmniAuth uses the wonderful icon set from <https://github.com/intridea/authbuttons>
#
# Usage:
#   In your Gemfile, add:
#
#       gem 'sinatra_omniauth'
#
#   In the root directory of your app (same dir as config.ru), add your API keys to "omniauth.yml"
#
#   In your application:
#
#       require 'sinatra/omniauth'
#
#       set :omniauth, YAML.load_file(File.dirname(__FILE__)+"/omniauth.yml")
#
#       register SinatraOmniAuth
#
#   Models:
#       Copy user.rb and authentication.rb from the models directory, and add any
#       other fields and relationships you need.
#
#   Routes which SinatraOmniAuth will handle (you may override these if needed):
#       /auth
#               presents a list of configured authentication services, including the
#               user's current sign-in account and any other registered accounts.
#               This page also includes a signout link and the ability to delete
#               secondary authentication methods.
#       /auth/signout
#               Signs the user out immediately and redirects to '/'
#       /auth/<provider>/callback
#               This URL is triggered when the authentication service redirects the user's
#               browser here, after a successful authentication. The handler signs in the
#               user, who may be a new user just joining, an existing user adding a new
#               authentication method, or an existing user signing in or changing to a
#               different authentication method
#       /auth/failure
#               Sets a flash saying that the authorization failed before redirecting to .
#       /auth/:id
#               A POST here with the magic _method=delete will delete this authentication
#               method from the current user's account
#
#   Views:
#       Copy views/auth.haml and css/auth.css to wherever they will be found.
#
#       Note that auth.haml uses assets helpers include_javascripts and include_stylesheets
#       to load packed or unpacked JS (jQuery required) and CSS. Youy'll be wanting to
#       style it all up yourself anyhow, but when you're there, replace the helpers as needed.
#
#   Images:
#       Use the authbuttons images as noted. auth.haml expects them to be in </images/authbuttons/>
#
#   Helper methods:
#       authenticate_user!
#               Redirects to /auth if the user is not already signed in
#       current_user
#               The User record of the current signed-in user
#       current_auth
#               The Authentication record with which the user is signed in.
#               Note that for most authentication services, this includes the user's name
#               and email address.
#
#   Make sure you add a handler for the following routes:
#       get '/auth/welcome'     - When a new user first joins
#       get '/auth/signedin'    - When the user signs in
#
#       These handlers may simply set a flash and redirect to another place.
#
#   Oh, did I say flash? SinatraOmniAuth uses the "rack-flash" gem, so you can say:
#
#       flash.notice = "Welcome back!"; redirect to('/')
#       ... and also access flash.error, flash.notice, etc, in your views.
#
#       You're welcome :)
#
require 'omniauth'
require 'openid/store/filesystem'
require 'rack-flash'

module SinatraOmniAuth
  module Helpers
    def current_user
      @current_user ||= User.get(session[:user_id]) if session[:user_id]
    end

    def current_auth
      @current_auth ||= Authentication.get(session[:authentication_id]) if session[:authentication_id]
    end

    def authenticate_user!
      if !current_user
        flash.error = 'You need to sign in before you can access this page!'
        redirect to('/auth')
      end
    end
  end

  def self.registered app
    # Register OmniAuth Strategies and keys for all providers:
    app.use ::OmniAuth::Builder do
      app.settings.omniauth.each do |a|
        provider = a['provider']
        client_options = a[:client_options]
        client_options = client_options ? {:client_options => client_options} : {}
        if key = a['key']
          provider provider, key, a['secret'], client_options
        else
          name = a['name'].downcase.gsub(/ /,' ')
          store = OpenID::Store::Filesystem.new(a['store']||'./tmp')
          provider provider, store, :name => name, :identifier => a['identifier']
        end
      end
    end

    # Make _method=delete work in POST requests:
    app.enable :method_override

    # Create a flash, so we can display a message after a redirect
    app.use Rack::Flash, :accessorize => [:notice, :error]
    app.send(:define_method, :flash) do
      env['x-rack.flash']
    end

    # A little help from our friends...
    app.send(:include, Helpers)

    # Display the authentication in use, registered for the current user, and available
    app.get '/auth' do
      @authentications_possible = settings.omniauth

      if current_user
        @authentication_current = Authentication.get(session[:authentication_id])
        @authentications_available = current_user.authentications.all(:order => [ :provider.desc ])
        @authentications_unused = @authentications_available.
          reject do|a|
            a.id == @authentication_current.id
          end
        @authentications_possible = @authentications_possible.dup.
          reject do |a|
            @authentications_available.detect{|p| p.provider.gsub(/[ _]/,'') == a['name'].downcase.gsub(/[ _]/,'') }
          end
      end

      haml :auth
    end

    app.get '/auth/:authentication/callback' do
      callback
    end

    app.post '/auth/:authentication/callback' do
      callback
    end

    app.send(:define_method, :callback) do
      # callback: success
      # This handles signing in and adding an authentication authentication to existing accounts itself

      # get the authentication parameter from the Rails router
      authentication_route = params[:authentication] ? params[:authentication] : 'No authentication recognized (invalid callback)'

      # get the full hash from omniauth
      omniauth = request.env['omniauth.auth']

      # continue only if hash and parameter exist
      unless omniauth and params[:authentication]
        flash.error = 'Error while authenticating via ' + authentication_route.capitalize + '. The authentication did not return valid data.'
        redirect to('/signin')
      end

      # create a new regularised authentication hash
      @authhash = Hash.new
      oaeuh = omniauth['extra'] && omniauth['extra']['user_hash']
      oaui = omniauth['user_info']
      if authentication_route == 'facebook'
        @authhash[:email] = oaeuh['email'] || ''
        @authhash[:name] = oaeuh['name'] || ''
        @authhash[:uid] = oaeuh['name'] || ''
        @authhash[:provider] = omniauth['provider'] || ''
      elsif authentication_route == 'github'
        @authhash[:email] = oaui['email'] || ''
        @authhash[:name] = oaui['name'] || ''
        @authhash[:uid] = (oaeuh['id'] || '').to_s
        @authhash[:provider] = omniauth['provider'] || ''
      elsif ['google', 'yahoo', 'linked_in', 'twitter', 'myopenid', 'openid', 'open_id'].index(authentication_route) != nil
        @authhash[:email] = oaui['email'] || ''
        @authhash[:name] = oaui['name'] || ''
        @authhash[:uid] = (omniauth['uid'] || '').to_s
        @authhash[:provider] = omniauth['provider'] || ''
      elsif authentication_route == 'aol'
        @authhash[:email] = oaui['email'] || ''
        @authhash[:name] = oaui['name'] || ''
        @authhash[:uid] = (omniauth['uid'] || '').to_s
        @authhash[:provider] = omniauth['provider'] || ''
      else
        # REVISIT: debug to output the hash that has been returned when adding new authentications
        return '<pre>'+omniauth.to_yaml+'</pre>'
      end

      if @authhash[:uid] == '' or @authhash[:provider] == ''
        flash.error = 'Error while authenticating via ' + authentication_route + '/' + @authhash[:provider].capitalize + '. The authentication returned invalid data for the user id.'
        redirect to('/auth')
      end

      auth = Authentication.first(:provider => @authhash[:provider], :uid => @authhash[:uid])

      # if the user is currently signed in, he/she might want to add another account to signin
      if current_user
        if auth
          flash.notice = 'You are now signed in using your' + @authhash[:provider].capitalize + ' account'
          session[:authentication_id] = auth.id     # They're now signed in using the new account
          redirect to('/auth/signedin')  # Already signed in, and we already had this authentication
        else
          auth = current_user.authentications.create!(:provider => @authhash[:provider], :uid => @authhash[:uid], :user_name => @authhash[:name], :user_email => @authhash[:email])
          flash.notice = 'Your ' + @authhash[:provider].capitalize + ' account has been added for signing in at this site.'
          session[:authentication_id] = auth.id     # They're now signed in using the new account
          session[:user_name] = @authhash[:name] if @authhash[:name] != ''
          redirect to('/auth/signedin')
        end
      else
        if auth
          # Signin existing user
          # in the session his user id and the authentication id used for signing in is stored
          session[:user_id] = auth.user.id
          session[:authentication_id] = auth.id
          session[:user_name] = @authhash[:name] if @authhash[:name] != ''

          flash.notice = 'Signed in successfully via ' + @authhash[:provider].capitalize + '.'
          redirect to('/auth/signedin')
        end

        # this is a new user; add them
        @current_user = User.create()
        session[:user_id] = @current_user.id
        session[:user_name] = @authhash[:name] if @authhash[:name] != ''
        auth = current_user.authentications.create!(:provider => @authhash[:provider], :uid => @authhash[:uid], :user_name => @authhash[:name], :user_email => @authhash[:email])
        session[:authentication_id] = auth.id
        redirect to('/auth/welcome')
      end
    end

    app.get '/auth/failure' do
      flash.error = 'There was an error at the remote authentication authentication. You have not been signed in.'
      redirect to('/')
    end

    app.get '/auth/signout' do
      authenticate_user!

      session[:user_id] = nil
      session[:user_name] = nil
      session[:authentication_id] = nil
      session.delete :user_id
      session.delete :user_name
      session.delete :authentication_id
      flash.notice = 'You have been signed out'
      redirect to('/')
    end

    # authentication
    app.delete '/auth/:id' do
      authenticate_user!

      # remove an authentication authentication linked to the current user
      @authentication = current_user.authentications.get(params[:id])

      if session[:authentication_id] == @authentication.id
        flash.error = 'You can\'t delete this authorization because you are currently signed in with it!'
      else
        @authentication.destroy
      end

      redirect to('/auth')
    end

  end
end
