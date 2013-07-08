

get '/test' do
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

def auth
  puts "auth"
  return true
end

before '/list/*' do
  auth()
end

before '/file/*' do
  auth()
end

before '/folder/*' do
  auth()
end

before '/revisions/*' do
  auth()
end

before '/share/*' do
  auth()
end

after '/**/*' do
  headers['Access-Control-Allow-Origin'] = '*'
end

