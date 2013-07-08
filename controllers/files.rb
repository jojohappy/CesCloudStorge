post "/file/move" do
  if params[:file_id].nil? then
    return {'result' => -1, 'error_msg' => 'file_id is empty'}.to_json
  end
  
  if params[:dest_folder_id].nil? then
    return {'result' => -1, 'error_msg' => 'dest_folder_id is empty'}.to_json
  end
  
  src_file_id = params[:file_id]
  dest_folder_id = params[:dest_folder_id]
  
  current_folder = nil
  files = src_file_id.split(",")
  files.each do |f|
    src_file = Files.find(f.to_i)
    if nil == src_file then
      return {'result' => -1, 'error_msg' => "File doesn't exists"}.to_json
    end
  
    flag = 0
    file_name = src_file.file_name
    dest_folder = Folder.find(dest_folder_id.to_i)
    if nil == dest_folder then
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
  
    current_folder = src_file.folders.first
    dest_folder_list = []
    dest_folder_list.push(dest_folder)
    src_file.file_name = file_name
    src_file.folders = dest_folder_list
    if !src_file.save then
      return {'result' => -1, 'error_msg' => src_file.errors}.to_json
    end
  end
  filelist = get_filelist(current_folder.folder_id)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end

def delete_filesystem(file)
  
end

def create_filesystem(file)

end

post "/file/copy" do
  if params[:file_id].nil? then
    return {'result' => -1, 'error_msg' => "file_id is empty"}.to_json
  end
  
  if params[:dest_folder_id].nil? then
    return {'result' => -1, 'error_msg' => "destination folder is empty"}.to_json
  end
  
  file_ids = params[:file_id]
  dest_folder_id = params[:dest_folder_id]
  
  files = file_ids.split(",")
  files.each do |file|
    dest_folder = Folder.find(dest_folder_id.to_i)
	copy_file = Files.find(file.to_i)
	current_folder = copy_file.folders.first
	copy_file_name = copy_file.file_name
    flag = 0
    begin
      flag = 0
	  dest_folder.files.each do |f|
	    if copy_file_name == f.file_name then
		  copy_file_name.insert(copy_file_name.index("."), "-Copy")
		  flag = 1
		end
	  end
    end while flag == 0
	new_file = Files.new
	#:mime_type, :user_id, :create_time, :last_modified, :path, :description :revisions, :file_size file_name
	new_file.mime_type = copy_file.mime_type
	new_file.user_id = copy_file.user_id
	new_file.create_time = Time.new
	new_file.last_modified = Time.new
    new_file.path = ""
	new_file.description = copy_file.description
	new_file.revisions = 1
	new_file.file_size = copy_file.size
	
	new_file.file_name = copy_file_name
	dest_folder_list = []
	dest_folder_list.push(dest_folder)
	new_file.folders = dest_folder_list
	if !new_file.save then
	  return {'result' => -1, 'error_msg' => new_file.errors}.to_json
	end
    file_path = create_filesystem(new_file)
	new_file.path = file_path
	new_file.save
  end
  filelist = get_filelist(current_folder.folder_id)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end

delete "/file/delete" do
  if params[:file_id].nil? then
    return {'result' => -1, 'error_msg' => "file_id is empty"}.to_json
  end
  
  if params[:is_forever].nil? then
    is_forever = 0
  else
    is_forever = 1
  end
  
  file_ids = params[:file_id]
  files = file_ids.split(",")
  files.each do |f|
    if is_forever == 0 then
      file = Files.find(f.to_i)
      dest_folder = Folder.find(1)
      dest_folder_list = []
      dest_folder_list.push(dest_folder)
	  current_folder = file.folders.first
      file.folders = dest_folder_list
      if !file.save then
        return {'result' => -1, 'error_msg' => file.errors}.to_json
      end
    elsif is_forever == 1 then
      file = Files.find(f.to_i)
	  current_folder = file.folders.first
	  # 文件系统删除文件
	  delete_filesystem(file)
	  file.destroy()
    else
      return {'result' => -1, 'error_msg' => 'is_forever error'}.to_json
    end
  end
  filelist = get_filelist(current_folder.folder_id)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end

post "/file/rename" do
  if params[:file_id].nil? then
    return {'result' => -1, 'error_msg' => "file_id is empty"}.to_json
  end
  
  if params[:new_file_name].nil? then
    return {'result' => -1, 'error_msg' => "file_name is empty"}.to_json
  end
  
  file_id = params[:file_id]
  new_file_name = params[:new_file_name]
  file = Files.find(file_id.to_i)
  current_folder = file.folders.first
  folder = Folder.find(current_folder.folder_id)
  folder.files.each do |f|
    if f.file_name == new_file_name && f.file_id != file_id.to_i then
	  return {'result' => -1, 'error_msg' => "File already exists"}.to_json
	end
  end
  
  file.file_name = new_file_name
  file.save
  filelist = get_filelist(current_folder.folder_id)
  {'result' => 0, 'total' => filelist.count(), 'filelist' => filelist}.to_json
end

