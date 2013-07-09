class AuthorizationCode < ActiveRecord::Base
  attr_accessible :authorization_id, :code, :redirect_uri, :client_id, :create_time, :last_modified, :status
end