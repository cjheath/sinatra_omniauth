class Authentication
  include DataMapper::Resource

  belongs_to :user

  property :id, Serial
  property :user_id, Integer
  property :provider, String
  property :uid, String, :length => 240
  property :user_name, String, :length => 240
  property :user_email, String, :length => 240
end
