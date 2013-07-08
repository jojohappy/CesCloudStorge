
get "/list/files" do
  content_type :json
  if params[:folder_id].nil? then
    # return {'result' => -1, 'error_msg' => 'folder_id is empty'}.to_json
    current_folder_id = "-1"
  else
    current_folder_id = params[:folder_id]
  end
  
  file_result = []
  if current_folder_id.to_i == -1 then
    current_folder_id = "3"
  end
  file_result = get_filelist(current_folder_id)
  {'result' => 0, 'total' => file_result.count(), 'filelist' => file_result}.to_json
end

get "/list/folders" do  
  content_type :json
  folderlist = []
  folderlist = get_folder_tree(3)
  {'result' => 0, 'folderlist' => folderlist}.to_json
end

def get_folder_tree(folder_id)
  folders = []
  folders.push(Folder.find(folder_id.to_i))
  fchildren = Folder.where("parent_folder_id=?", folder_id.to_s)
  if nil != fchildren && 0 != fchildren.count() then
    fchildren.each do |folder|
      folders.push(get_folder_tree(folder.folder_id))
    end
  end
  return folders
end

get "/list/synchrony" do

end

get "/list/search" do
  content_type :json
  if params[:search_text].nil? then
    return {'result' => -1, 'error_msg' => 'search text is empty'}.to_json
  end
  search_text = params[:search_text]
  
  folderlist = Folder.where("folder_name like '%#{search_text}%'")
  filelist = Files.where("file_name like '%#{search_text}%'")
  search_result = convertRecord2Struct(folderlist, filelist)
  {'result' => 0, 'filelist' => search_result, 'total' => search_result.count()}.to_json
end

def convertRecord2Struct(folderlist, filelist)
  file_result = []
  folderlist.each do |folder|
    fd = FileStruct.new(-1, folder.folder_id, folder.folder_name, "", -1, folder.create_time.strftime('%Y-%m-%d %I:%M:%S'), folder.last_modified.strftime('%Y-%m-%d %I:%M:%S'), "", folder.user_id, "", "", folder.description)
    file_result.push(fd)
  end
  
  filelist.each do |file|
    f = FileStruct.new(file.file_id, -1, file.file_name, file.mime_type, file.file_size, file.create_time.strftime('%Y-%m-%d %I:%M:%S'), file.last_modified.strftime('%Y-%m-%d %I:%M:%S'), "", file.user_id, "", "", file.description)
    file_result.push(f)
  end
  return file_result
end

def get_filelist(folder_id)
  file_result = []
  folderlist = Folder.where("parent_folder_id=?", folder_id.to_s)
  current_folder = Folder.find(folder_id.to_i)
  filelist = current_folder.files
  file_result = convertRecord2Struct(folderlist, filelist)
  return file_result
end