require 'rubygems'
require 'mongo'
require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/synchrony'
require 'json'
require 'fiber'
require 'rack/fiber_pool'

include Mongo

get '/' do
	listarray = []
	
	db = MongoClient.new("172.17.10.217", 27017, :pool_size => 5, :pool_timeout => 5).db("ces")
	coll=db.collection("ces")
	coll.insert({"name" => "MongoDBtest"})
	# arr = coll.find.to_a
	# arr.each { |t| puts t.inspect}
	#coll.find.each { |row|  listarray.push(row.inspect) }
	
	#content_type :json
	#listarray.to_json
end