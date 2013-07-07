
post '/user/login' do
  if params[:username].nil? then
    return {'result' => -1, 'error_msg' => 'user name is empty'}.to_json
  end
  if params[:password].nil? then
    return {'result' => -1, 'error_msg' => 'password is empty'}.to_json
  end
  username = params[:username]
  password = params[:password]
  
  response = RestClient.post 'http://172.17.10.76:8080/cas-server/v1/authenticateUser', {:username => username, :password => password}, {:content_type => :json, :accept => :json}
  content_type :json
  response
end