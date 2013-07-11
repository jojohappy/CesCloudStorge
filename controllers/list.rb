
get "/list/files" do
  content_type :json
  if params[:folder_id].nil? then
    # return {'result' => -1, 'error_msg' => 'folder_id is empty'}.to_json
    current_folder_id = "-1"
  else
    current_folder_id = params[:folder_id]
  end
  
  if params[:sort].nil? then
    sort = ""
  else
    sort = params[:sort]
  end
  
  if params[:reverse].nil? then
    reverse = 0
  else
    reverse = params[:reverse]
  end
  root_folder_id = get_user_root_folder
  file_result = []
  if current_folder_id.to_i == -1 then
    # 获得用户根目录
    current_folder_id = root_folder_id
    if current_folder_id == -1 then
      status 400
      return {'result' => -1, 'error_msg' => 'root folder does not exists'}.to_json
    end
  end
  trash_folder_id = get_user_trash_folder
  if current_folder_id.to_i == -10 then
    # 获得用户回收站目录
    current_folder_id = trash_folder_id
  end
  file_result = get_filelist(current_folder_id, sort, reverse)
  # 递归查询父文件夹
  current_folder = Folder.find(current_folder_id.to_i)
  folder_result = get_folderlist(current_folder)
  if current_folder_id.to_i == trash_folder_id then
    root_folder = Folder.find(root_folder_id)
    folder_result.push(root_folder)
  end
  {'result' => 0, 'total' => file_result.count(), 'filelist' => file_result, 'folderlist' => folder_result, 'parent_folder_id'=>current_folder.parent_folder_id}.to_json
end

get "/list/folders" do  
  content_type :json
  folderlist = []
  root_folder_id = get_user_root_folder
  if root_folder_id == -1 then
    status 400
    return {'result' => -1, 'error_msg' => 'root folder does not exists'}.to_json
  end
  folderlist = get_folder_tree(root_folder_id)
  {'result' => 0, 'folderlist' => folderlist}.to_json
end

get "/list/synchrony" do

end

get "/list/search" do
  content_type :json
  if params[:search_text].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'search text is empty'}.to_json
  end
  search_text = params[:search_text]
  
  folderlist = Folder.where("folder_name like '%#{search_text}%'")
  filelist = Files.where("file_name like '%#{search_text}%'")
  search_result = convertRecord2Struct(folderlist, filelist)
  {'result' => 0, 'filelist' => search_result, 'total' => search_result.count()}.to_json
end


post "/list/move" do
  content_type :json
  if params[:dest_folder_id].nil? || "" == params[:dest_folder_id] then
    status 400
    return {'result' => -1, 'error_msg' => 'dest_folder_id is empty'}.to_json
  end
  
  Folder.transaction do
    Files.transaction do
      src_file_id = params[:file_id]
      dest_folder_id = params[:dest_folder_id]
      if nil != src_file_id && "" != src_file_id then
        move_file(src_file_id, dest_folder_id)
      end
  
      src_folder_ids = params[:folder_id]
  
      if nil != src_folder_ids && "" != src_folder_ids then
        move_folder(src_folder_ids, dest_folder_id)
      end
      {'result' => 0}.to_json
    end
  end
end

post "/list/delete" do
  content_type :json
  if params[:is_forever].nil? then
    is_forever = 0
  else
    is_forever = params[:is_forever]
  end
  
  folder_id = params[:folder_id]
  if nil != folder_id && "" != folder_id then
    delete_folder(folder_id, is_forever)
  end
  
  
  file_ids = params[:file_id]
  if nil != file_ids && "" != file_ids then
    delete_file(file_ids, is_forever)
  end
  {'result' => 0}.to_json
end


def get_folderlist(current_folder)
  folders = []
  #current_folder = Folder.find(folder_id.to_i)
  folders.push(current_folder)
  if current_folder.parent_folder_id.to_i <= 0 then
    return folders
  end
  fparent = Folder.find(current_folder.parent_folder_id.to_i)
  return folders.concat(get_folderlist(fparent))
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

def convertRecord2Struct(folderlist, filelist)
  file_result = []
  folderlist.each do |folder|
    fd = FileStruct.new(-1, folder.folder_id, folder.folder_name, "", -1, folder.create_time.strftime('%Y-%m-%d %H:%M:%S'), folder.last_modified.strftime('%Y-%m-%d %H:%M:%S'), "", folder.username, "", "", folder.description, folder.origin_folder)
    file_result.push(fd)
  end
  
  filelist.each do |file|
    f = FileStruct.new(file.file_id, -1, file.file_name, file.mime_type, file.file_size, file.create_time.strftime('%Y-%m-%d %I:%M:%S'), file.last_modified.strftime('%Y-%m-%d %H:%M:%S'), "", file.username, "", "", file.description, file.origin_folder)
    file_result.push(f)
  end
  return file_result
end

def get_filelist(folder_id, sort, reverse)
  file_result = []
  folderlist = []

  folder_sort = ""
  file_sort = ""
  if "file_name" == sort then
    folder_sort = "folder_name"
    file_sort = "file_name"
  elsif "file_size" == sort then
    folder_sort = ""
    file_sort = "file_size"
  else
    folder_sort = sort
    file_sort = sort
  end
  
  if 1 == reverse.to_i then
    folderlist = "" == folder_sort ? Folder.where("parent_folder_id=?", folder_id.to_s).order("folder_name").reverse_order : Folder.where("parent_folder_id=?", folder_id.to_s).order(folder_sort).reverse_order
  else
    folderlist = "" == folder_sort ? Folder.where("parent_folder_id=?", folder_id.to_s).order(:folder_name) : Folder.where("parent_folder_id=?", folder_id.to_s).order(folder_sort)
  end
  root_id = get_user_root_folder
  trash_id = get_user_trash_folder
  trash_folder = Folder.find(trash_id)
  trash_folder_list = []
  trash_folder_list.push(trash_folder)
  if folder_id.to_i == trash_id || folder_id.to_i != root_id then
    
  else
    folderlist = trash_folder_list + folderlist
  end
  current_folder = Folder.find(folder_id.to_i)
  if 1 == reverse.to_i then
    filelist = "" == file_sort ? current_folder.files.order("file_name").reverse_order : current_folder.files.order(file_sort).reverse_order
  else
    filelist = "" == file_sort ? current_folder.files.order("file_name") : current_folder.files.order(file_sort)
  end
  file_result = convertRecord2Struct(folderlist, filelist)
  return file_result
end

