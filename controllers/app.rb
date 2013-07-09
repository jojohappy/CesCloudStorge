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
  name = params[:fname]
  
  aname = name.split(".")
  
  if aname.count() >= 2 then
    if nil == aname[0] || "" == aname[0] then
	  p "extname = none"
	else
	  if nil == aname[-1] || "" == aname[-1] then
	    p "extname = none1"
	  else
	    p "extname = #{aname[-1]}"
	  end
	end
  else
    p "extname = none3"
  end
  
end

def auth
  if params[:access_token].nil? then
    if env['Authorization'].nil? then
	  return false
	else
	  token = env['Authorization']
	end
  else
    token = params[:access_token]
  end
  
  # 检查是否存在token
  accessToken = Token.where('access_token=?', token.to_s)
  if nil == accessToken then
    return false
  else
    # 检查是否超时
    if isExpire(accessToken) then
	  # accessToken.destory()
	  return false
	end
  end
  accessToken.create_time = Time.new
  accessToken.last_modified = Time.new
  accessToken.save
  return true
end

def isExpire(accessToken)
  return Time.new.to_i > accessToken.create_time.to_i + accessToken.expires_in
end

before '/list/*' do
  # auth()
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

