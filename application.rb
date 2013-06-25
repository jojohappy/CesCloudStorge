require 'mongo'
require 'sinatra'
require 'sinatra/synchrony'

include Mongo

configure do
  # = Configuration =
  set :run,             false
  set :show_exceptions, development?
  set :raise_errors,    development?
  set :logging,         true
  set :static,          false # your upstream server should deal with those (nginx, Apache)
  conn = MongoClient.new("172.17.10.218", 27017)
  set :mongo_connection, conn
  set :mongo_db, conn.db('test')
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
  logger.level = ::Logger::DEBUG
else
  logger = ::Logger.new("/dev/null")
end

# load project config
APP_CONFIG = YAML.load_file(File.expand_path("../config", __FILE__) + '/app_config.yml')[ENV["RACK_ENV"]]


#MongoDB = MongoClient.new("10.0.0.9", 27017, :pool_size => 20, :pool_timeout => 5).db("test")
#MongoDB = MongoClient.new("172.17.10.218", 27017, :pool_size => 20, :pool_timeout => 5).db("test")

# initialize redis cache
# CACHE = ActiveSupport::Cache::DalliStore.new("127.0.0.1")

# Set autoload directory
%w{models controllers lib}.each do |dir|
  Dir.glob(File.expand_path("../#{dir}", __FILE__) + '/**/*.rb').each do |file|
    require file
  end
end
