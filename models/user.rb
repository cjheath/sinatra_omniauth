require 'dm-core'
require 'dm-timestamps'

class User
  include DataMapper::Resource
  
  property :id,          Serial
  property :name,        String
  property :email,       String
  property :created_at,  DateTime
  property :updated_at,  DateTime

  has n, :authorizations
end
