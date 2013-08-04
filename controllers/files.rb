# encoding: utf-8

post "/file/move" do
  content_type :json
  if params[:file_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'file_id is empty'}.to_json
  end
  
  if params[:dest_folder_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'dest_folder_id is empty'}.to_json
  end
  
  src_file_id = params[:file_id]
  dest_folder_id = params[:dest_folder_id]
  Files.transaction do
    move_file(src_file_id, dest_folder_id)
  end
end


post "/file/copy" do
  content_type :json
  if params[:file_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => "file_id is empty"}.to_json
  end
  
  if params[:dest_folder_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => "destination folder is empty"}.to_json
  end
  
  file_ids = params[:file_id]
  dest_folder_id = params[:dest_folder_id]
  
  Files.transaction do
    copy_file(file_ids, dest_folder_id)
  end
  
end

post "/file/delete" do
  content_type :json
  if params[:file_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => "file_id is empty"}.to_json
  end
  
  if params[:is_forever].nil? then
    is_forever = 0
  else
    is_forever = params[:is_forever]
  end
  
  file_ids = params[:file_id]
  Files.transaction do
    delete_file(file_ids, is_forever)
  end
end

post "/file/rename" do
  content_type :json
  if params[:file_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => "file_id is empty"}.to_json
  end
  
  if params[:new_file_name].nil? then
    status 400
    return {'result' => -1, 'error_msg' => "file_name is empty"}.to_json
  end
  
  file_id = params[:file_id]
  new_file_name = params[:new_file_name].strip
  if new_file_name == "回收站" then 
    status 400
    return {'result' => -1, 'error_msg' => "不能重命名为回收站"}.to_json
  end
  Files.transaction do
    begin
        file = Files.find(file_id.to_i)
    rescue ActiveRecord::RecordNotFound => e
      status 400
      return {'result' => -1, 'error_msg' => "File not exists"}.to_json
    end
    current_folder = file.folders.first
    folder = Folder.find(current_folder.folder_id)
    folder.files.each do |f|
      if f.file_name == new_file_name && f.file_id != file_id.to_i then
        status 400
        return {'result' => -1, 'error_msg' => "File already exists"}.to_json
      end
    end
  
    if file.file_name == new_file_name then
      return {'result' => 0}.to_json
    end
  
    file.file_name = new_file_name
    file_old_mime_type = file.mime_type
    #获得文件名后缀
    new_mime_type = get_extname(new_file_name)
    file.mime_type = new_mime_type
    file_real_name = get_filename_without_extname new_file_name
    file_old_path = file.path
  
    file.path = Digest::MD5.hexdigest(file_real_name.encode('utf-8'))
    file.last_modified = Time.new
    #文件系统修改名称
    modify_filesystem(file, file_old_path, file_old_mime_type)
    if !file.save then
      status 500
      return {'result' => -1, 'error_msg' => file.errors}.to_json
    end
  end
  #filelist = get_filelist(current_folder.folder_id, "", 0)
  {'result' => 0}.to_json
end


get "/file/download" do
  p "download"
  if params[:file_id].nil? then
    p "file_id is null"
    content_type :json
    status 400
    return {'restult' => -1, 'error_msg' => 'Missing required parameter: file_id'}.to_json
  end

  p "aas"
  file_id = params[:file_id]
  begin
      file = Files.find(file_id.to_i)
  rescue ActiveRecord::RecordNotFound => e
    content_type :json
    status 400
    return {'result' => -1, 'error_msg' => "File doesn't exists"}.to_json
  end
  
  # 判断用户是否有权限下载
  # if @username != file.username then
  if "testuser" != file.username then
    count = FileShare.where("username = ? and entity='share' and file_id=?", "testuser", file_id.to_s).count
	if count == 0 then
	  content_type :json
      status 400
      return {'result' => -1, 'error_msg' => "You can not download this file!"}.to_json
	end
  end
  
  filerealpath = nil
  filerealpath = concat_file_path(file)

  mime_type = file.mime_type
  begin
    content_type mime_type
  rescue RuntimeError => e
    content_type :default
  end
  #send_file filerealpath, :filename=>file.file_name
  
  user_agent = request.user_agent.downcase
  filename = user_agent.include?("msie") ? CGI::escape(file.file_name) : file.file_name
  response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
  response.headers['X-Accel-Redirect'] = "/filesd" + filerealpath
end


post "/file/upload" do
  #username = session[:username]
  username = "testuser"
  p "upload"
  if params[:current_folder_id].nil? then
    status 400
    content_type :json
    return {'restult' => -1, 'error_msg' => 'Missing required parameter: current_folder_id'}.to_json
  end
  
  current_folder_id = params[:current_folder_id]
  current_folder = Folder.find(current_folder_id.to_i)
  upload_file_name = String.new(params['attachment'][:filename])
  upload_file_name1 = String.new(params['attachment'][:filename])
  flag = 0
  current_folder.files.each do |file|
    if file.file_name == upload_file_name then
      flag = 1
      break
    end
  end
  
  if 1== flag then
    status 400
	p "File already exists"
    return "File already exists"
  end
  
  # 获得扩展名
  ext_name = get_extname(upload_file_name)
  # 获得文件名(无扩展名)
  file_name = get_filename_without_extname(upload_file_name1)
  
  new_file = Files.new
  new_file.mime_type = ext_name
  new_file.username = username
  new_file.create_time = Time.new
  new_file.last_modified = Time.new
  new_file.path = Digest::MD5.hexdigest(file_name.encode('utf-8'))
  new_file.description = ""
  new_file.revisions = 1

  new_file.file_name = params['attachment'][:filename]
  dest_folder_list = []
  dest_folder_list.push(current_folder)
  new_file.folders = dest_folder_list
  new_file.file_size = 0
  if !new_file.save then
    status 400
    content_type :json
    return {'result' => -1, 'error_msg' => new_file.errors}.to_json
  end
  
  real_file_path = _ROOT_FILE_STORE + "/" + username
  if !Dir.exists?(real_file_path) then
    Dir.mkdir(real_file_path, 0755)
  end
  
  real_file_path = _ROOT_FILE_STORE + "/" + username + "/" + new_file.file_id.to_s
  if !Dir.exists?(real_file_path) then
    Dir.mkdir(real_file_path, 0755)
  end
  
  real_file_path = _ROOT_FILE_STORE + "/" + username + "/" + new_file.file_id.to_s + "/v" + new_file.revisions.to_s
  if !Dir.exists?(real_file_path) then
    Dir.mkdir(real_file_path, 0755)
  end
  if nil == new_file.mime_type || "" == new_file.mime_type || "default" == new_file.mime_type then
    real_file_path = real_file_path + '/' + new_file.path
  else
    real_file_path = real_file_path + '/' + new_file.path + "." + new_file.mime_type
  end
  File.open(real_file_path, "w") do |f|
    f.write(params['attachment'][:tempfile].read)
  end
  
  new_file.file_size = File.size(real_file_path)
  
  if !new_file.save then
    status 400
    content_type :json
    return {'result' => -1, 'error_msg' => new_file.errors}.to_json
  end
  
  upload_device = params[:upload_device]


  if nil == upload_device then
    status 200
    return "success"
  end
  
  if "android" == upload_device then
    content_type :json
    status 200
    return {'result' => 0, 'file_id' => new_file.file_id}.to_json 
  end

end

def move_file(src_file_id, dest_folder_id)
  current_folder = nil
  files = src_file_id.split(",")
  files.each do |f|
    filesystemflag = 0
    src_file = Files.find(f.to_i)
    if nil == src_file then
      status 400
      return {'result' => -1, 'error_msg' => "File doesn't exists"}.to_json
    end
  
    flag = 0
    file_name = src_file.file_name
    dest_folder = Folder.find(dest_folder_id.to_i)
    if nil == dest_folder then
      status 400
      return {'result' => -1, 'error_msg' => "Folder doesn't exists"}.to_json
    end
    dest_file = dest_folder.files
    begin
      dest_file.each do |file|
        flag = 0
        if file.file_name == file_name then
          file_name.insert(file_name.index('.'), "-Copy")
          flag = 1
          break
        end
      end
    end while flag == 1
    if file_name != src_file.file_name then
      filesystemflag = 1
    end
    current_folder = src_file.folders.first
    dest_folder_list = []
    dest_folder_list.push(dest_folder)
    src_file.file_name = file_name
    src_file.folders = dest_folder_list
    file_real_name = get_filename_without_extname file_name
    file_old_path = src_file.path
    file_old_mime_type = src_file.mime_type
    src_file.path = Digest::MD5.hexdigest(file_real_name.encode('utf-8'))
    src_file.last_modified = Time.new
    if !src_file.save then
      status 400
      return {'result' => -1, 'error_msg' => src_file.errors}.to_json
    end
    # 文件系统修改名称
    if filesystemflag == 1 then
      modify_filesystem(src_file, file_old_path, file_old_mime_type)
    end
  end
  filelist = get_filelist(current_folder.folder_id, "", 0)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end


def delete_filesystem(file)
  filedirpath = _ROOT_FILE_STORE + file.username + "/" + file.file_id.to_s
  FileUtils.rm_rf(Dir.glob(filedirpath))
end


def create_filesystem(file, realfile)
  
end


def copy_filesystem(file, src_file)
  # 创建新的文件夹id、版本
  file_id_path = _ROOT_FILE_STORE + file.username + "/" + file.file_id.to_s
  file_revisions_path = _ROOT_FILE_STORE + file.username + "/" + file.file_id.to_s + "/v" + file.revisions.to_s
  Dir.mkdir(file_id_path, 0775)
  Dir.mkdir(file_revisions_path, 0775)
  if nil == src_file.mime_type || "" == src_file.mime_type || "default" == src_file.mime_type then
    new_real_file_path = file_revisions_path + "/" + src_file.path
  else
    new_real_file_path = file_revisions_path + "/" + src_file.path + "." + src_file.mime_type
  end
  # 获得原文件
  src_real_file_path = concat_file_path(src_file)
  # 复制该文件到新版本文件夹下
  FileUtils.cp(src_real_file_path, new_real_file_path)
  # 重命名文件
  if file.file_name != src_file.file_name then
    # 得到新的加密文件名
    file_real_name = get_filename_without_extname file.file_name
    new_file_path = Digest::MD5.hexdigest(file_real_name.encode('utf-8'))
    file.path = new_file_path
    modify_filesystem(file, src_file.path, src_file.mime_type)
    return new_file_path
  else
    return src_file.path
  end
end


def modify_filesystem(file, file_old_path, file_old_mime_type)
  if nil == file_old_mime_type || "" == file_old_mime_type || "default" == file_old_mime_type then
    filerealpath = _ROOT_FILE_STORE + file.username + "/" + file.file_id.to_s + "/v" + file.revisions.to_s + "/" + file_old_path
  else
    filerealpath = _ROOT_FILE_STORE + file.username + "/" + file.file_id.to_s + "/v" + file.revisions.to_s + "/" + file_old_path + "." + file_old_mime_type
  end
  
  new_filerealpath = concat_file_path(file)
  
  File.rename(filerealpath, new_filerealpath)
end


def concat_file_path(file)
  if nil == file.mime_type || "" == file.mime_type || "default" == file.mime_type then
    filerealpath = _ROOT_FILE_STORE + file.username + "/" + file.file_id.to_s + "/v" + file.revisions.to_s + "/" + file.path
  else
    filerealpath = _ROOT_FILE_STORE + file.username + "/" + file.file_id.to_s + "/v" + file.revisions.to_s + "/" + file.path + "." + file.mime_type
  end
  return filerealpath
end

def get_extname(file_name)
  fname_array = file_name.split(".")
  
  if fname_array.count() >= 2 then
    if nil == fname_array[0] || "" == fname_array[0] then
      return "default"
    else
      if nil == fname_array[-1] || "" == fname_array[-1] then
        return "default"
      else
        return fname_array[-1]
      end
    end
  else
    return "default"
  end
end


def get_filename_without_extname(file_name)
  fname_array = file_name.split(".")
  
  if fname_array.count() >= 2 then
    if nil == fname_array[0] || "" == fname_array[0] then
      return file_name
    else
      if nil == fname_array[-1] || "" == fname_array[-1] then
        return file_name
      else
        filename = ""
        for i in 0..fname_array.count() - 2
          filename.concat(fname_array[i])
          if (i + 2) < fname_array.count() then
            filename.concat(".")
          end
        end
        return filename
      end
    end
  else
    return file_name
  end
end



def copy_file(file_ids, dest_folder_id)
  files = file_ids.split(",")
  current_folder = nil
  files.each do |file|
    dest_folder = Folder.find(dest_folder_id.to_i)
    copy_file = Files.find(file.to_i)
	# 判断用户是否有权限下载
    # if @username != file.username then
    if "testuser" != copy_file.username then
      count = FileShare.where("username = ? and entity='share' and file_id=?", "testuser", copy_file.file_id.to_s).count
	  if count == 0 then
	    content_type :json
        status 400
        return {'result' => -1, 'error_msg' => "You can not copy this file!"}.to_json
	  end
    end
    current_folder = copy_file.folders.first
    copy_file_name = String.new(copy_file.file_name)
    flag = 0
    begin
      flag = 0
      dest_folder.files.each do |f|
        if copy_file_name == f.file_name then
         copy_file_name.insert(copy_file_name.index("."), "-Copy")
         flag = 1
        end
      end
    end while flag == 1
    new_file = Files.new
    new_file.mime_type = copy_file.mime_type
    new_file.username = copy_file.username
    new_file.create_time = Time.new
    new_file.last_modified = Time.new
    new_file.path = ""
    new_file.description = copy_file.description
    new_file.revisions = 1
    new_file.file_size = copy_file.file_size

    new_file.file_name = copy_file_name
    dest_folder_list = []
    dest_folder_list.push(dest_folder)
    new_file.folders = dest_folder_list
    if !new_file.save then
      status 400
      return {'result' => -1, 'error_msg' => new_file.errors}.to_json
    end
    file_path = copy_filesystem(new_file, copy_file)
    new_file.path = file_path
    new_file.save
  end
  filelist = get_filelist(current_folder.folder_id, "", 0)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end


def delete_file(file_ids, is_forever)
  current_folder = nil
  files = file_ids.split(",")
  files.each do |f|
    begin
      file = Files.find(f.to_i)
    rescue ActiveRecord::RecordNotFound => e
      status 400
      return {'result' => -1, 'error_msg' => "File not exists"}.to_json
    end
    # 获得用户回收站folder_id
    trash_folder_id = get_user_trash_folder
    if trash_folder_id == -1 then
      status 400
      return {'result' => -1, 'error_msg' => 'trash folder does not exists'}.to_json
    end
    #trash_folder_id = 1
    
    if is_forever.to_i == 0 then
	  if file.folders.first.folder_id == trash_folder_id then
        status 400
        return {'result' => -1, 'error_msg' => "File not exists"}.to_json
      end
      dest_folder = Folder.find(trash_folder_id)
      dest_folder_list = []
      dest_folder_list.push(dest_folder)
      current_folder = file.folders.first
      file.origin_folder = current_folder.folder_id
      file.folders = dest_folder_list
      if !file.save then
        status 500
        return {'result' => -1, 'error_msg' => file.errors}.to_json
      end
	  # 删除file share
	  array_file = FileShare.where("file_id=?", f.to_s)
      array_file.each do |file|
        file.destroy()
      end
    elsif is_forever.to_i == 1 then
      #file = Files.find(f.to_i)
      #current_folder = file.folders.first
      # 文件系统删除文件
      delete_filesystem(file)
      file.destroy()
    else
      status 400
      return {'result' => -1, 'error_msg' => 'is_forever error'}.to_json
    end
  end
  #filelist = get_filelist(current_folder.folder_id, "", 0)
  {'result' => 0}.to_json
end
