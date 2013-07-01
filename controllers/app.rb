require 'json'

def db
  @@db ||=
  db = EventMachine::Synchrony::ConnectionPool.new(size: 20) do
    #newdb = EM::Mongo::Connection.new('172.16.0.9', 27017, 1, {:reconnect_in => 1}).db('test')
    #newdb = EM::Mongo::Connection.new('172.17.10.137', 27017, 1, {:reconnect_in => 1}).db('admin')
    newdb = EM::Mongo::Connection.new('172.17.10.215', 27017, 1, {:reconnect_in => 1}).db('admin')
    newdb.authenticate('root', '123456')
    newdb
  end
  return @@db
end

get '/' do
  listarray = []
  #db.collection("users").insert({"item" => "user11166", "py" => 16})
  content_type :json
  coll = db.collection("users")

  rep = EM::Synchrony.sync coll.find.defer_as_a
  listarray = rep.each do |doc|
    doc
  end
  listarray.to_json
end
