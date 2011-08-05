class User
  include DataMapper::Resource

  devise :registerable,   # handles signing up users through a registration process, also edit/destroy account.
         :rememberable,   # "Remember me" from a cookie
         :trackable       # Tracks sign in count, timestamps and IP address

  property :id, Serial

  # Each user may log in using different methods:
  has n, :authentications
end
