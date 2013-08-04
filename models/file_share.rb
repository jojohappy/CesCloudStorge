class FileShare < ActiveRecord::Base
	belongs_to :file, :class_name => 'Files'
	attr_accessible :id, :file_id, :username, :entity, :link, :tenant
end