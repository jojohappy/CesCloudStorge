class FolderFileRel < ActiveRecord::Base
	belongs_to :file
	belongs_to :folder
end