require 'json'

def db
  @@db ||=
    db = EventMachine::Synchrony::ConnectionPool.new(size: 20) do
      EM::Mongo::Connection.new('172.16.0.9', 27017, 1, {:reconnect_in => 1}).db('test')
    end
  return @@db
end

get '/' do
	listarray = []
	db.collection("users").find.each do |doc|
	  if doc then
	  aa = doc['_id'].to_s
	  #listarray.push(aa)
	  end
	end
	#db.collection("users").insert({"item" => "user111", "py" => 13})
	content_type :json
	puts listarray.count()
	listarray.to_json
end
