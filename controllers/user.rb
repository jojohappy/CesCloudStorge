
get '/user/login' do
  if params[:username].nil? then
    return {'result' => -1, 'error_msg' => 'user name is empty'}.to_json
  end
  if params[:password].nil? then
    return {'result' => -1, 'error_msg' => 'password is empty'}.to_json
  end
  username = params[:username]
  password = params[:password]
  
  #response = RestClient.post 'http://172.17.10.76:8080/cas-server/v1/authenticateUser', {:username => username, :password => password}, {:content_type => :json, :accept => :json}
  #json = JSON.parse(response.body)
  content_type :json
  #{'username' => username, 'result' => json['result']}.to_json
  {'username' => username, 'result' => 0}.to_json
end

get "/user/used_space" do
  content_type :json
  #username = session[:username]
  username = "testuser"
  root_path = _ROOT_FILE_STORE + username
  if !Dir.exists?(root_path) then
    Dir.mkdir(root_path, 0755)
  end
  size = get_user_space(_ROOT_FILE_STORE, username)
  {'used_space' => size, 'result' => 0}.to_json
end

get "/tenants" do
  content_type :json
  #调用外部web service获得当前用户的租户列表
  #RestClient.post("http://172.17.10.76:8080/cas-server/v1/getTenantList/#{@username}", {}, {:content_type => :json, :accept => :json}){ |response, request, result, &block| 
  RestClient.post("http://172.17.10.199/cas-server/v1/getTenantList/user1@ce-service.com.cn", {}, {:content_type => :json, :accept => :json}){ |response, request, result, &block| 
    tenants = JSON.parse(response.body)
	status 200
    {'result' => 0, 'tenants' => tenants['tenants']}.to_json
  }
end

get "/logout" do
  session[:cas_ticket] = nil
  session[:cas_user] = nil
  status 200
  #redirect _CAS_BASE_URL + "/logout"
end

def get_user_space(path, file)
  size = 0
  filepath = path + "/" + file
  if File.directory?(filepath) then
    list = Dir.entries(filepath)
    list.each do |children|
      if children == "." || children == ".." then
        next
      end
      size = size + get_user_space(filepath, children)
    end
    return size
  else
    return File.size(filepath)
  end
end

def get_user_root_folder
  #username = session[:username]
  username = "testuser"
  root_folder = Folder.where("username=? and parent_folder_id = -1", username).first
  if nil == root_folder then
    return -9999
  end
  return root_folder.folder_id
end

def get_user_trash_folder
  #username = session[:username]
  username = "testuser"
  trash_folder = Folder.where("username=? and parent_folder_id = -10", username).first
  if nil == trash_folder then
    return -9999
  end
  return trash_folder.folder_id
end

def get_user_share_folder
  #username = session[:username]
  username = "testuser"
  share_folder = Folder.where("username=? and parent_folder_id = -20", username).first
  if nil == share_folder then
    return -9999
  end
  return share_folder.folder_id
end


