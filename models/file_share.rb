class FileShare < ActiveRecord::Base
	belongs_to :file
	attr_accessible :id, :file_id, :username, :entity, :link
end