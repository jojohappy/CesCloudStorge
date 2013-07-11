
get '/user/login' do
  if params[:username].nil? then
    return {'result' => -1, 'error_msg' => 'user name is empty'}.to_json
  end
  if params[:password].nil? then
    return {'result' => -1, 'error_msg' => 'password is empty'}.to_json
  end
  username = params[:username]
  password = params[:password]
  
  response = RestClient.post 'http://172.17.10.76:8080/cas-server/v1/authenticateUser', {:username => username, :password => password}, {:content_type => :json, :accept => :json}
  json = JSON.parse(response.body)
  content_type :json
  {'username' => username, 'result' => json['result']}.to_json
end

get "/user/used_space" do
  content_type :json
  #username = session[:username]
  username = "testuser"
  size = get_user_space(_ROOT_FILE_STORE, username)
  {'used_space' => size, 'result' => 0}.to_json
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
    return -1
  end
  return root_folder.folder_id
end

def get_user_trash_folder
  #username = session[:username]
  username = "testuser"
  trash_folder = Folder.where("username=? and parent_folder_id = -10", username).first
  if nil == trash_folder then
    return -1
  end
  return trash_folder.folder_id
end

