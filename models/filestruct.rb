class FileStruct < Struct.new(:file_id,:folder_id,:name,:mime_type,:size,:create_time,:last_modified,:username,:revision_info,:share,:description, :origin_folder, :parent_folder_id)
end
