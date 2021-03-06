class Files < ActiveRecord::Base
  #has_one :folder_file_rel, :dependent => :destroy
  self.table_name = 'files'
  has_many :file_shares, foreign_key: 'file_id', :dependent => :destroy
  has_and_belongs_to_many :folders, foreign_key: 'files_id', :join_table=>"folder_file_rels"
  attr_accessible :file_id, :mime_type, :username, :create_time, :last_modified, :path, :description, :origin_folder

  validates :revisions, :file_size, numericality: true
  validates :file_name, presence: true
end