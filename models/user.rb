require 'uuidtools'

class User
  include DataMapper::Resource

  property :id, UUID, :key => true, :required => true, :default => proc { UUIDTools::UUID.random_create }

  # Each user may log in using different methods:
  has n, :authentications
end
