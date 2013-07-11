class Folder < ActiveRecord::Base
  #has_many :folder_file_rel, :dependent => :destroy
  has_and_belongs_to_many :files, :class_name => 'Files', foreign_key: 'folder_id', :join_table=>"folder_file_rels"
  attr_accessible :folder_id, :username, :create_time, :last_modified, :description, :origin_folder

  validates :parent_folder_id, numericality: true, presence: true
  validates :folder_name, presence: true
end