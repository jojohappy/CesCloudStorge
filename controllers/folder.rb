
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
  else
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
  end
end

def delete_filesystem(file)
  
end

post "/folder/move" do
  if params[:folder_id] then
    return {'result' => -1, 'error_msg' => 'source folder_id is empty'}.to_json
  end
  if params[:dest_folder_id] then
    return {'result' => -1, 'error_msg' => 'destination folder_id is empty'}.to_json
  end
  src_folder_id = params[:folder_id]
  dest_folder_id = params[:dest_folder_id]
  
  folder = Folder.find(src_folder_id.to_i)
  parent_src_folder_id = folder.parent_folder_id
  folder.parent_folder_id = dest_folder_id.to_i
  folder.save
  filelist = get_filelist(parent_src_folder_id)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end

post "/folder/rename" do
  if params[:folder_id] then
    return {'result' => -1, 'error_msg' => 'source folder_id is empty'}.to_json
  end
  
  if params[:new_folder_name] then
    return {'result' => -1, 'error_msg' => 'folder\'s name is empty'}.to_json
  end
  
  src_folder_id = params[:folder_id]
  new_folder_name = params[:new_folder_name]
  
  folder = Folder.find(src_folder_id.to_i)
  parent_src_folder_id = folder.parent_folder_id
  folder.folder_name = new_folder_name.to_s
  folder.save
  filelist = get_filelist(parent_src_folder_id)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end

post "/folder/create" do
  if params[:parent_folder_id] then
    return {'result' => -1, 'error_msg' => 'parent folder_id is empty'}.to_json
  end
  
  if params[:new_folder_name] then
    return {'result' => -1, 'error_msg' => 'folder\'s name is empty'}.to_json
  end
  
  parent_folder_id = params[:parent_folder_id]
  new_folder_name = params[:new_folder_name]
  
  new_folder = Folder.create(name: "David", occupation: "Code Artist")
end

