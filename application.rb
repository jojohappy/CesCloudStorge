require 'em-mongo'
require 'sinatra'
require 'sinatra/synchrony'

configure do
  # = Configuration =
  set :run,             false
  set :show_exceptions, development?
  set :raise_errors,    development?
  set :logging,         true
  set :static,          true # your upstream server should deal with those (nginx, Apache)
  set :public_folder, File.dirname(__FILE__) + '/public'
end

configure :production do
end  

# initialize log
require 'logger'
Dir.mkdir('log') unless File.exist?('log')
class ::Logger; alias_method :write, :<<; end
case ENV["RACK_ENV"]
when "production"
  logger = ::Logger.new("log/production.log")
  logger.level = ::Logger::WARN
when "development"
  logger = ::Logger.new(STDOUT)
  #logger = ::Logger.new("log/development.log")
  logger.level = ::Logger::DEBUG
else
  logger = ::Logger.new("/dev/null")
end

# Sets up database configuration
ActiveRecord::Base.establish_connection YAML::load(File.open('config/database.yml'))[ENV["RACK_ENV"]]
# ActiveRecord::Base.logger = logger
ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = false
  self.default_timezone = :local
  self.time_zone_aware_attributes = false
  self.logger = logger
end

# Sets MondoDB
def db
  @@db ||=
  db = EventMachine::Synchrony::ConnectionPool.new(size: 20) do
    #newdb = EM::Mongo::Connection.new('172.16.0.9', 27017, 1, {:reconnect_in => 1}).db('test')
    #newdb = EM::Mongo::Connection.new('172.17.10.137', 27017, 1, {:reconnect_in => 1}).db('admin')
    newdb = EM::Mongo::Connection.new('172.17.10.216', 30000, 1, {:reconnect_in => 1}).db('admin')
    newdb.authenticate('root', '123456')
    newdb
  end
  return @@db
end

#root file store path
def _ROOT_FILE_STORE
  return "/home/cesteam/cloudstorge/"
end 

# load project config
APP_CONFIG = YAML.load_file(File.expand_path("../config", __FILE__) + '/app_config.yml')[ENV["RACK_ENV"]]

# initialize redis cache
# CACHE = ActiveSupport::Cache::DalliStore.new("127.0.0.1")
use Rack::Session::Pool, :expire_after => 2592000
use Rack::Sendfile


# Set autoload directory
%w{models controllers lib}.each do |dir|
  Dir.glob(File.expand_path("../#{dir}", __FILE__) + '/**/*.rb').each do |file|
    require file
  end
end
