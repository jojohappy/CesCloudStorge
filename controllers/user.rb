
post '/user/login' do
  username = params[:username]
  password = params[:password]
  
  response = RestClient.post 'http://172.17.10.76:8080/cas-server/v1/authenticateUser', {:username => username, :password => password}, {:content_type => :json, :accept => :json}
  content_type :json
  response
end