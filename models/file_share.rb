class FileShare < ActiveRecord::Base
	belongs_to :file
	attr_accessible :id, :file_id, :user_id, :entity, :link
end