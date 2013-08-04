require 'digest'
get "/oauth2/auth" do
  content_type :json
  if params[:response_type].nil? then
    status 400
    return {'restult' => -1, 'error_msg' => 'Missing required parameter: response_type'}.to_json
  end
  if params[:client_id].nil? then
    status 400
    return {'restult' => -1, 'error_msg' => 'Missing required parameter: client_id'}.to_json
  end

  if params[:username].nil? then
    status 400
    return {'restult' => -1, 'error_msg' => 'Missing required parameter: username'}.to_json
  end
  if params[:password].nil? then
    status 400
    return {'restult' => -1,'error_msg' => 'Missing required parameter: password'}.to_json
  end
  
  #if params[:redirect_uri].nil? then
    #status 400
    #return {'restult' => -1,'error_msg' => 'Missing required parameter: redirect_uri'}.to_json
  #end
  
  if params[:scope].nil? then
    scope = "all"
  else
    scope = params[:scope]
  end
  
  response_type = params[:response_type]
  client_id = params[:client_id]
  username = params[:username]
  password = params[:password]
  redirect_uri = params[:redirect_uri]
  
  if response_type != "code" then
    status 400
    return {'restult' => -1, 'error_msg' => "Invalid response_type: #{response_type}"}.to_json
  end
  
  # 用户名密码校验
  #RestClient.post('http://172.17.10.210/cas-server/v1/authenticateUser', {:username => username, :password => password}, {:content_type => :json, :accept => :json}){ |response, request, result, &block| 
    #json = JSON.parse(response.body)
    #if json['result'] == "failure" then
      #{'result' => -1, 'error_msg' => 'Error: invalid user name or password'}.to_json
    #end
  #}
  
  coll = db.collection("register_clients")
  rep = EM::Synchrony.sync coll.find({:client_id => client_id}).defer_as_a
  registerClient = rep.first
  registerClient = registerClient.to_json
  #registerClient = RegisterClient.find(client_id.to_i)
  if nil == registerClient then
    status 400
    return {'restult' => -1, 'error_msg' => "Error: invalid_client"}.to_json
  end
  
  code = Digest::MD5.hexdigest(SecureRandom.base64.encode('utf-8'))
  db.collection("authorization_codes").insert({"code" => code, "redirect_uri" => registerClient['redirect_uri'], "client_id" => registerClient['client_id'], "create_time" => Time.new, "last_modified" => Time.new, "status" => 1})
  
  #authorization = AuthorizationCode.new
  #authorization.code = code
  #authorization.redirect_uri = registerClient.redirect_uri
  #authorization.client_id = registerClient.client_id
  #authorization.create_time = Time.new
  #authorization.last_modified = Time.new
  #authorization.status = 1
  #if !authorization.save then
    #status 400
    #return {'restult' => -1, 'error_msg' => authorization.errors}.to_json
  #end
  
  session[:username] = username
  root_folder_id = get_user_root_folder
  return {'code' => code, 'username' => username, 'root_folder_id' => root_folder_id}.to_json
end

post "/oauth2/token" do
  content_type :json
  if params[:code].nil? then
    status 400
    return {'restult' => -1, 'error_msg' => 'Missing required parameter: code'}.to_json
  end
  if params[:client_id].nil? then
    status 400
    return {'restult' => -1, 'error_msg' => 'Missing required parameter: client_id'}.to_json
  end

  if params[:client_secret].nil? then
    status 400
    return {'restult' => -1, 'error_msg' => 'Missing required parameter: client_secret'}.to_json
  end
  if params[:grant_type].nil? then
    status 400
    return {'restult' => -1,'error_msg' => 'Missing required parameter: grant_type'}.to_json
  end
  
  code = params[:code]
  client_id = params[:client_id]
  client_secret = params[:client_secret]
  redirect_uri = params[:redirect_uri]
  grant_type = params[:grant_type]
  
  if grant_type != "authorization_code" then
    status 400
    return {'restult' => -1, 'error_msg' => "Invalid grant_type: #{grant_type}"}.to_json
  end
  
  # auth = AuthorizationCode.where("code = '#{code}'").first
  coll = db.collection("authorization_codes")
  rep = EM::Synchrony.sync coll.find({:code => code}).defer_as_a
  auth = rep.first
  auth = auth.to_json
  
  if nil == auth then
    status 400
    return {'restult' => -1, 'error_msg' => "Invalid code: #{code}"}.to_json
  end
  #if auth.status == 0 then
  if auth['status'].to_i == 0 then
    status 400
    return {'restult' => -1, 'error_msg' => "#{code} has been expired"}.to_json
  end
  
  #client = RegisterClient.where("client_id='#{client_id}' and client_secret='#{client_secret}'").first
  coll = db.collection("register_clients")
  rep = EM::Synchrony.sync coll.find({:client_id => client_id, :client_secret => client_secret}).defer_as_a
  client = rep.first
  client = client.to_json
  if nil == client then
    status 400
    return {'restult' => -1, 'error_msg' => "Invalid client_id or client_secret."}.to_json
  end
  
  @auth = Rack::Auth::Basic::Request.new(request.env)
  if @auth.provided? && @auth.basic? && @auth.credentials && 
    #@auth.credentials == [auth.client_id, client.client_secret]
    @auth.credentials == [auth['client_id'], client['client_secret']]
  elsif params[:client_id] && params[:client_secret]
  else
    status 401
    return {'restult' => -1, 'error_msg' => "error"}.to_json
  end
  #auth.status = 0
  #auth.save
  db.collection("authorization_codes").safe_update({:authorization_id => auth['authorization_id']}, {:status => 0})
  
  username = session[:username]
  #token = Token.new
  #token.access_token = Digest::MD5.hexdigest(SecureRandom.base64.encode('utf-8'))
  #token.refresh_token = Digest::MD5.hexdigest(SecureRandom.uuid.encode('utf-8'))
  #token.token_type = "Bearer"
  #token.expires_in = 86400
  #token.authorization_id = auth.authorization_id
  #token.create_time = Time.new
  #token.last_modified = Time.new
  #token.username = username
  #if !token.save then
    #status 400
    #return {'restult' => -1, 'error_msg' => token.errors}.to_json
  #end
  #token.to_json
  access_token = Digest::MD5.hexdigest(SecureRandom.base64.encode('utf-8'))
  refresh_token = Digest::MD5.hexdigest(SecureRandom.uuid.encode('utf-8'))
  db.collection("tokens").insert({"access_token" => access_token, "refresh_token" => refresh_token, "token_type" => "Bearer", "expires_in" => 86400, "authorization_id" => auth['authorization_id'], "username" => username, "create_time" => Time.new, "last_modified" => Time.new, "status" => 1})
  status 200
  {'access_token' => access_token, 'token_type' => "Bearer", 'expires_in' => 86400, 'refresh_token' => refresh_token}.to_json
  
end

get "/oauth2/register_client" do
  # client_id SecureRandom.random_number(10000000000)+.app.boc-service.com
  # client_secret SecureRandom.urlsafe_base64
  
end