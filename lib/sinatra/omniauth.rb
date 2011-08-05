require 'omniauth'
require 'openid/store/filesystem'
require 'rack-flash'

module SinatraOmniAuth
  module Helpers
    def current_user
      @current_user ||= User.get(session[:user_id]) if session[:user_id]
    end

    def authenticate_user!
      if !current_user
        flash.error = 'You need to sign in before you can access this page!'
        redirect to('/auth/signin')
      end
    end
  end

  def self.registered app
    # Register OmniAuth Strategies and keys for all providers:
    app.use ::OmniAuth::Builder do
      app.settings.omniauth.each do |a|
        provider = a['provider']
        if key = a['key']
          provider provider, key, a['secret'], (a['client_options'] || {})
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
            @authentications_available.detect{|p| p.provider == a['provider'] }
          end
      end

      haml :auth
    end

    app.get '/auth/signin' do
      @authentications = settings.omniauth.map{|a| a['name']}
      haml :signin, :layout => :auth_layout
    end

    app.get '/auth/:authentication/callback' do
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
      oaeuh = omniauth['extra']['user_hash']
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

    # auth_failure
    app.get '/auth/failure' do
      # {:action=>"failure", :controller=>"authentications"}
      flash.error = 'There was an error at the remote authentication authentication. You have not been signed in.'
      redirect to('/')
    end

    # signout_authentications
    app.get '/auth/signout' do
      # {:action=>"signout", :controller=>"authentications"}
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

    # failure_authentications
    app.get '/auth/failure' do
      # {:action=>"failure", :controller=>"authentications"}
      haml :failure
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

    # test_users
    app.get '/users/test' do
      # {:action=>"test", :controller=>"users"}
      authenticate_user!
      haml :user_test
    end

    # users
    app.get '/users' do
      # {:action=>"index", :controller=>"users"}
      authenticate_user!
      haml :users
    end

  end
end
