# encoding: utf-8

post "/folder/delete" do
  content_type :json
  if params[:folder_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'folder_id is empty'}.to_json
  end
  if params[:is_forever].nil? then
    is_forever = 0
  else
    is_forever = params[:is_forever]
  end
  folder_id = params[:folder_id]
  Folder.transaction do
    Files.transaction do
      delete_folder(folder_id, is_forever)
    end
  end
end


post "/folder/move" do
  content_type :json
  if params[:folder_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'source folder_id is empty'}.to_json
  end
  if params[:dest_folder_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'destination folder_id is empty'}.to_json
  end
  src_folder_ids = params[:folder_id]
  dest_folder_id = params[:dest_folder_id]
  
  Folder.transaction do
    move_folder(src_folder_ids, dest_folder_id)
  end
end

post "/folder/rename" do
  content_type :json
  if params[:folder_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'source folder_id is empty'}.to_json
  end
  
  if params[:new_folder_name].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'folder\'s name is empty'}.to_json
  end
  
  
  
  Folder.transaction do
    filelist = []
    src_folder_id = params[:folder_id]
    new_folder_name = params[:new_folder_name].strip
  
    if new_folder_name == "回收站" then 
      status 400
      return {'result' => -1, 'error_msg' => "不能重命名为回收站"}.to_json
    end
  
    folder = Folder.find(src_folder_id.to_i)
    parent_src_folder_id = folder.parent_folder_id
    folderfind = Folder.where('parent_folder_id' => parent_src_folder_id, 'folder_name' => new_folder_name).first
    if nil != folderfind && new_folder_name == folderfind.folder_name then
      status 400
      return {'result' => -1, 'error_msg' => "Folder \'#{new_folder_name}\' already exists."}.to_json
    end
    folder.folder_name = new_folder_name.to_s
    folder.last_modified = Time.new
    folder.save
    filelist = get_filelist(parent_src_folder_id, "", 0)
    {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
  end
end

post "/folder/create" do
  content_type :json
  if params[:parent_folder_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'parent folder_id is empty'}.to_json
  end
  
  if params[:new_folder_name].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'folder\'s name is empty'}.to_json
  end
  
  Folder.transaction do
    filelist = []
    parent_folder_id = params[:parent_folder_id]
    new_folder_name = params[:new_folder_name]
    if -1 == parent_folder_id.to_i then
      parent_folder_id = get_user_root_folder
    end
    newfolder = Folder.where('parent_folder_id' => parent_folder_id.to_i, 'folder_name' => new_folder_name).first_or_initialize
    if nil == newfolder || nil == newfolder.folder_id then
      newfolder.username = "testuser"
      newfolder.create_time = Time.new
      newfolder.last_modified = Time.new
      newfolder.parent_folder_id = parent_folder_id
      newfolder.folder_name = new_folder_name
      if newfolder.valid? then
        newfolder.save
      else
        status 400
        return {'result' => -1, 'error_msg' => newfolder.errors}.to_json
      end
    
      filelist = get_filelist(parent_folder_id, "", 0)
      {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist, 'new_folder_id' => newfolder.folder_id.to_i}.to_json
    else
      return {'result' => -1, 'error_msg' => "Folder \'#{new_folder_name}\' already exists"}.to_json
    end
  end
end

def delete_folder(folder_id, is_forever)
  parent_folder = nil
  folders = folder_id.split(",")
  folders.each do |fd| 
    parent_folder = Folder.find(fd.to_i)
    delete_folder_singal(fd, is_forever)
  end
  #filelist = get_filelist(parent_folder.folder_id, "", 0)
  {'result' => 0}.to_json
end

def delete_folder_singal(folder_id, is_forever)
  if 0 == is_forever.to_i then
    folder = Folder.find(folder_id.to_i)
    trash_folder_id = get_user_trash_folder
    origin_folder = folder.parent_folder_id
    if trash_folder_id == -1 then
      status 400
      return {'result' => -1, 'error_msg' => 'trash folder does not exists'}.to_json
    end
    folder.origin_folder = origin_folder
    folder.parent_folder_id = trash_folder_id
    folder.save
  elsif 1 == is_forever.to_i then
    folder = Folder.find(folder_id.to_i)
    files = folder.files
    files.each do |tmp|
      file = Files.find(tmp.file_id)
      #文件系统删除文件
      delete_filesystem(file)
      file.destroy()
    end
    fchildren = Folder.where("parent_folder_id=?", folder_id.to_s)
    if nil == fchildren || 0 == fchildren.count() then
      folder.destroy()
      return
    else
      fchildren.each do |child|
        delete_folder_singal(child.folder_id, is_forever)
      end
      folder.destroy()
      return
    end
  else
    status 400
    return {'result' => -1, 'error_msg' => 'is_forever error'}.to_json
  end
end

def move_folder(src_folder_ids, dest_folder_id)
  parent_src_folder_id = -1
  folders = src_folder_ids.split(",")
  error_flag_a = 0
  folders.each do |fd| 
    error_flag = 0
    begin
      folder = Folder.find(fd.to_i)
    rescue ActiveRecord::RecordNotFound => e
	  raise ActiveRecord::Rollback
      status 400
      return {'result' => -1, 'error_msg' => "Folder doesn't exists."}.to_json
    end
    #判断是否为当前目录的子目录
    dest_folder = Folder.find(dest_folder_id.to_i)
    folder_tree = get_folderlist(dest_folder)
    folder_tree.each do |foldertmp|
      if foldertmp.folder_id == fd.to_i then
        error_flag = 1
        error_flag_a = 1
        break
      end
    end
    
    if error_flag == 1 then
      raise ActiveRecord::Rollback
	  status 400
	  return {'result' => -1, 'error_msg' => "destination folder is child of source folder!"}.to_json
    end

    folder_name = folder.folder_name
    flag = 0
    begin
      folderfind = Folder.where('parent_folder_id' => dest_folder_id.to_i, 'folder_name' => folder_name).first
      if nil != folderfind && folder_name == folderfind.folder_name then
        folder_name = folder_name + "-Copy"
        flag = 1
      else
        flag = 0
      end
    end while flag == 1
    folder.folder_name = folder_name
    parent_src_folder_id = folder.parent_folder_id
    folder.parent_folder_id = dest_folder_id.to_i
	folder.last_modified = Time.new
    if !folder.save then
	  raise ActiveRecord::Rollback
      status 400
      return {'result' => -1, 'error_msg' => folder.errors}.to_json
    end
  end
  if error_flag_a == 1 then
    raise ActiveRecord::Rollback
    status 400
    return {'result' => -1, 'error_msg' => "destination folder is child of source folder!"}.to_json
  end
  if parent_src_folder_id == -1 then
    return {'result' => 0}.to_json
  end
  filelist = get_filelist(parent_src_folder_id, "", 0)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end
