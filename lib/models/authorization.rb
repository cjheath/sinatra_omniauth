require 'dm-core'
require 'dm-timestamps'

class Authorization
  include DataMapper::Resource
  belongs_to :user

  property :id,          Serial
  property :user_id,     Integer
  property :provider,    String
  property :uid,         String
  property :uname,       String
  property :uemail,      String
  property :created_at,  DateTime
  property :updated_at,  DateTime
end
