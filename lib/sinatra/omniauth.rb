module Sinatra
  module Omniauth
    module Helpers
      def current_user
        @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
      end

      def user_signed_in?
        return 1 if current_user
      end

      def authenticate_user!
        if !current_user
          # flash[:error] = 'You need to sign in before you can access this page!'
          redirect_to '/authentications/signin' # signin_authentications_path
        end
      end
    end

    def self.registered app

      app.get '/auth/:authentication/callback' do
        # {:action=>"create", :controller=>"authentications"}

        # callback: success
        # This handles signing in and adding an authentication authentication to existing accounts itself
        # It renders a separate view if there is a new user to create
        # get the authentication parameter from the Rails router
        authentication_route = params[:authentication] ? params[:authentication] : 'No authentication recognized (invalid callback)'

        # get the full hash from omniauth
        omniauth = request.env['omniauth.auth']

        # continue only if hash and parameter exist
        if omniauth and params[:authentication]

          # map the returned hashes to our variables first - the hashes differs for every authentication

          # create a new hash
          @authhash = Hash.new

          oaeuh = omniauth['extra']['user_hash']
          oaui = omniauth['user_info']
          if authentication_route == 'facebook'
            oaeuh['email'] ? @authhash[:email] = oaeuh['email'] : @authhash[:email] = ''
            oaeuh['name'] ? @authhash[:name] = oaeuh['name'] : @authhash[:name] = ''
            oaeuh['id'] ? @authhash[:uid] = oaeuh['id'].to_s : @authhash[:uid] = ''
            omniauth['provider'] ? @authhash[:provider] = omniauth['provider'] : @authhash[:provider] = ''
          elsif authentication_route == 'github'
            oaui['email'] ? @authhash[:email] = oaui['email'] : @authhash[:email] = ''
            oaui['name'] ? @authhash[:name] = oaui['name'] : @authhash[:name] = ''
            oaeuh['id'] ? @authhash[:uid] = oaeuh['id'].to_s : @authhash[:uid] = ''
            omniauth['provider'] ? @authhash[:provider] = omniauth['provider'] : @authhash[:provider] = ''
          elsif ['google', 'yahoo', 'twitter', 'myopenid', 'open_id'].index(authentication_route) != nil
            oaui['email'] ? @authhash[:email] = oaui['email'] : @authhash[:email] = ''
            oaui['name'] ? @authhash[:name] = oaui['name'] : @authhash[:name] = ''
            omniauth['uid'] ? @authhash[:uid] = omniauth['uid'].to_s : @authhash[:uid] = ''
            omniauth['provider'] ? @authhash[:provider] = omniauth['provider'] : @authhash[:provider] = ''
          else
            # debug to output the hash that has been returned when adding new authentications
            return '<pre>'+omniauth.to_yaml+'</pre>'
          end

          if @authhash[:uid] != '' and @authhash[:provider] != ''

            auth = Authentication.find_by_provider_and_uid(@authhash[:provider], @authhash[:uid])

            # if the user is currently signed in, he/she might want to add another account to signin
            if user_signed_in?
              if auth
                flash[:notice] = 'Your account at ' + @authhash[:provider].capitalize + ' is already connected with this site.'
                redirect_to '/authentications/'
              else
                current_user.authentications.create!(:provider => @authhash[:provider], :uid => @authhash[:uid], :uname => @authhash[:name], :uemail => @authhash[:email])
                flash[:notice] = 'Your ' + @authhash[:provider].capitalize + ' account has been added for signing in at this site.'
                redirect_to '/authentications/'
              end
            else
              if auth
                # signin existing user
                # in the session his user id and the authentication id used for signing in is stored
                session[:user_id] = auth.user.id
                session[:authentication_id] = auth.id

                flash[:notice] = 'Signed in successfully via ' + @authhash[:provider].capitalize + '.'
                redirect_to root_url
              else
                # this is a new user; show signup; @authhash is available to the view and stored in the sesssion for creation of a new user
                session[:authhash] = @authhash
                haml :signup
              end
            end
          else
            flash[:error] = 'Error while authenticating via ' + authentication_route + '/' + @authhash[:provider].capitalize + '. The authentication returned invalid data for the user id.'
            redirect_to signin_path
          end
        else
          flash[:error] = 'Error while authenticating via ' + authentication_route.capitalize + '. The authentication did not return valid data.'
          redirect_to signin_path
        end
      end

      # auth_failure
      app.get '/auth/failure' do
        # {:action=>"failure", :controller=>"authentications"}
        flash[:error] = 'There was an error at the remote authentication authentication. You have not been signed in.'
        redirect_to root_url
      end

      # signin_authentications
      app.get '/authentications/signin' do
        # {:action=>"signin", :controller=>"authentications"}
        haml :signin
      end

      # signout_authentications
      app.get '/authentications/signout' do
        # {:action=>"signout", :controller=>"authentications"}
        authenticate_user!

        session[:user_id] = nil
        session[:authentication_id] = nil
        session.delete :user_id
        session.delete :authentication_id
        flash[:notice] = 'You have been signed out'
        redirect_to '/'
      end

      # signup_authentications
      app.get '/authentications/signup' do
        # {:action=>"signup", :controller=>"authentications"}
        authenticate_user!
        haml :signup
      end

      # newaccount_authentications
      app.post '/authentications/newaccount' do
        # {:action=>"newaccount", :controller=>"authentications"}
        # POST from signup view
        if params[:commit] == "Cancel"
          session[:authhash] = nil
          session.delete :authhash
          redirect_to '/'
        else  # create account
          @newuser = User.new
          ah = session[:authhash]
          @newuser.name = ah[:name]
          @newuser.email = ah[:email]
          @newuser.authentications.build(:provider => ah[:provider], :uid => ah[:uid], :uname => ah[:name], :uemail => ah[:email])

          if @newuser.save!
            # signin existing user
            # in the session his user id and the authentication id used for signing in is stored
            session[:user_id] = @newuser.id
            session[:authentication_id] = @newuser.authentications.first.id

            flash[:notice] = 'Your account has been created and you have been signed in!'
            redirect_to '/'
          else
            flash[:error] = 'This is embarrassing! There was an error while creating your account from which we were not able to recover.'
            redirect_to '/'
          end
        end
      end

      # failure_authentications
      app.get '/authentications/failure' do
        # {:action=>"failure", :controller=>"authentications"}
        haml :failure
      end

      # authentications
      app.get '/authentications' do
        # {:action=>"index", :controller=>"authentications"}
        authenticate_user!
        @authentications = current_user.authentications.order('provider asc')
        haml :authentications
      end

      app.post '/authentications' do
        # {:action=>"create", :controller=>"authentications"}
        authenticate_user!
        haml :authentications
      end

      # authentication
      app.delete /authentications/:id' do
        # {:action=>"destroy", :controller=>"authentications"}
        authenticate_user!

        # remove an authentication authentication linked to the current user
        @authentication = current_user.authentications.find(params[:id])

        if session[:authentication_id] == @authentication.id
          flash[:error] = 'You can't delete this authorization because you are currently signed in with it!'
        else
          @authentication.destroy
        end

        redirect_to '/authentications/'
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

      # root
      app.get '/' do
        # {:action=>"index", :controller=>"users"}
        haml :root
      end

    end
  end
end
