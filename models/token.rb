class Token < ActiveRecord::Base
  attr_accessible :id, :access_token, :refresh_token, :token_type, :expire_in, :authorization_id, :create_time, :last_modified, :username
  
  def to_json
    {
      access_token: access_token,
      token_type: token_type,
      expires_in: expires_in,
      refresh_token: refresh_token
    }.to_json
  end
end