
delete "/folder/delete" do
  content_type :json
  if params[:folder_id].nil? then
    return {'result' => -1, 'error_msg' => 'folder_id is empty'}.to_json
  end
  if params[:is_forever].nil? then
    is_forever = 0
  else
    is_forever = params[:is_forever]
  end
  folder_id = params[:folder_id]
  
  folders = folder_id.split(",")
  folders.each do |fd| 
    delete_folder(fd, is_forever)
  end
  
  
end

def delete_folder(folder_id, is_forever)
  if 0 == is_forever.to_i then
    folder = Folder.find(folder_id.to_i)
    folder.parent_folder_id = 1
    folder.save
  elsif 1 == is_forever then
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
        delete_folder(child.folder_id, is_forever)
      end
      folder.destroy()
      return
    end
  else
    return {'result' => -1, 'error_msg' => 'is_forever error'}.to_json
  end
end

post "/folder/move" do
  if params[:folder_id].nil? then
    return {'result' => -1, 'error_msg' => 'source folder_id is empty'}.to_json
  end
  if params[:dest_folder_id].nil? then
    return {'result' => -1, 'error_msg' => 'destination folder_id is empty'}.to_json
  end
  src_folder_ids = params[:folder_id]
  dest_folder_id = params[:dest_folder_id]
  
  parent_src_folder_id = -1
  folders = src_folder_ids.split(",")
  folders.each do |fd| 
    folder = Folder.find(fd.to_i)
    if nil == folder then
      return {'result' => -1, 'error_msg' => "Folder doesn't exists."}.to_json
    end
  
    folder_name = folder.folder_name
    flag = 0
    begin
      folderfind = Folder.where('parent_folder_id' => dest_folder_id.to_i, 'folder_name' => folder_name)
      if nil != folderfind && folder_name == folderfind.folder_name then
        foler_name = folder_name + "-Copy"
        flag = 1
      else
        flag = 0
      end
    end while flag == 1
    folder.folder_name = foler_name
    parent_src_folder_id = folder.parent_folder_id
    folder.parent_folder_id = dest_folder_id.to_i
    folder.save
  end
  filelist = get_filelist(parent_src_folder_id)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end

post "/folder/rename" do
  if params[:folder_id].nil? then
    return {'result' => -1, 'error_msg' => 'source folder_id is empty'}.to_json
  end
  
  if params[:new_folder_name].nil? then
    return {'result' => -1, 'error_msg' => 'folder\'s name is empty'}.to_json
  end
  filelist = []
  src_folder_id = params[:folder_id]
  new_folder_name = params[:new_folder_name]
  
  folder = Folder.find(src_folder_id.to_i)
  parent_src_folder_id = folder.parent_folder_id
  folderfind = Folder.where('parent_folder_id' => parent_src_folder_id, 'folder_name' => new_folder_name)
  if nil != folderfind && new_folder_name == folderfind.folder_name then
    return {'result' => -1, 'error_msg' => "Folder \'#{new_folder_name}\' already exists."}.to_json
  end
  folder.folder_name = new_folder_name.to_s
  folder.save
  filelist = get_filelist(parent_src_folder_id)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end

post "/folder/create" do
  if params[:parent_folder_id].nil? then
    return {'result' => -1, 'error_msg' => 'parent folder_id is empty'}.to_json
  end
  
  if params[:new_folder_name].nil? then
    return {'result' => -1, 'error_msg' => 'folder\'s name is empty'}.to_json
  end
  filelist = []
  parent_folder_id = params[:parent_folder_id]
  new_folder_name = params[:new_folder_name]
  newfolder = Folder.where('parent_folder_id' => parent_folder_id, 'folder_name' => new_folder_name).first_or_initialize
  if nil == newfolder || nil == newfolder.folder_id then
    newfolder.user_id = 1
    newfolder.create_time = Time.new
    newfolder.last_modified = Time.new
    newfolder.parent_folder_id = parent_folder_id
    newfolder.folder_name = new_folder_name
    if newfolder.valid? then
      newfolder.save
    else      
      return {'result' => -1, 'error_msg' => newfolder.errors}.to_json
    end
  
    filelist = get_filelist(parent_folder_id)
    {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
  else
    return {'result' => -1, 'error_msg' => "Folder \'#{new_folder_name}\' already exists"}.to_json
  end

end

