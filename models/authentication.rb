class Authentication
  include DataMapper::Resource

  belongs_to :user

  property :id, Serial
  property :user_id, Integer
  property :provider, String
  property :uid, String
  property :user_name, String
  property :user_email, String
end
