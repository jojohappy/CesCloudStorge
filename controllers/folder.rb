
post "/folder/delete" do
  content_type :json
  folder_id = params[:folder_id]
  is_forever = params[:is_forever]
  
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

get "/folder/move" do
  
end


