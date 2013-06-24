require 'json'

get '/' do
	listarray = []
	coll=MongoDB.collection("users")
	coll.find.each { |row|  listarray.push(row.inspect) }
	content_type :json
	listarray.to_json
end