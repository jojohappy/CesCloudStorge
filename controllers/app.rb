require 'json'

get '/' do
	listarray = []
	#coll=MongoDB.collection("users")
	#coll.insert({"item" => "user222", "py" => 14})
	#coll.find.each { |row|  listarray.push(row.inspect) }
	settings.mongo_db['users'].insert({"item" => "user111", "py" => 13})
	#settings.mongo_db['users'].find.each { |row|  listarray.push(row.inspect) }
	#content_type :json
	#listarray.to_json
end