class Authentication
  include DataMapper::Resource

  belongs_to :user, :key => true

  # Authentication provider:
  property :provider, String, :key => true

  # User ID allocated by that provider:
  property :uid, String, :length => 240

  # User name and email:
  property :user_name, String, :length => 240
  property :user_email, String, :length => 240, :index => true
end
