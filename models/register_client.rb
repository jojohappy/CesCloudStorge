class RegisterClient < ActiveRecord::Base
  attr_accessible :client_id, :client_secret, :scope, :authorized_grant_types, :redirect_uri, :client_name, :create_time, :last_modified, :note
end