get "/" do
  redirect '/index.html'
end

get '/test' do
  #listarray = []
  #db.collection("users").insert({"item" => "user11166", "py" => 16})
  #content_type :json
  #coll = db.collection("users")

  #rep = EM::Synchrony.sync coll.find.defer_as_a
  #listarray = rep.each do |doc|
    #doc
  #end
  #listarray.to_json
  #encoding: utf-8
  name = params[:name]
  p Digest::MD5.hexdigest(name.encode('utf-8'))
end

def auth
  if params[:access_token].nil? then
    if env['Authorization'].nil? then
      return "Missing required parameter: access_token"
    else
      token = env['Authorization']
    end
  else
    token = params[:access_token]
  end
  
  # 检查是否存在token
  accessToken = Token.where('access_token=?', token.to_s).first
  if nil == accessToken then
    return "Token doesn't exists"
  else
    # 检查是否超时
    if isExpire(accessToken) then
      # accessToken.destory()
      return "Token has been expired"
    end
    # 检查session中的username是否和token的相同
    username = session[:username]
    if nil == username || "" == username then
      return "no session"
    end
    
    if username != accessToken.username then
      return "not current user"
    end
  end
  accessToken.create_time = Time.new
  accessToken.last_modified = Time.new
  accessToken.save
  return "success"
end

def isExpire(accessToken)
  return Time.new.to_i > accessToken.create_time.to_i + accessToken.expires_in
end

before '/list/*' do
  # content_type: json
  # if "success" != (msg = auth()) then
    #{'result' => -1, 'error_msg' => msg}.to_json
  # end
end

before '/file/*' do
  # auth()
end

before '/folder/*' do
  # auth()
end

before '/revisions/*' do
  # auth()
end

before '/share/*' do
  # auth()
end

after '/**/*' do
  headers['Access-Control-Allow-Origin'] = '*'
end

not_found do
  status 200
  content_type :png
end