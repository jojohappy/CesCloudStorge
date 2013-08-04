# encoding: utf-8
get "/share" do
  content_type :json
  if params[:file_id].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'Missing required parameter: file_id'}.to_json
  end
  
  if params[:entity].nil? then
    status 400
    return {'result' => -1, 'error_msg' => 'Missing required parameter: entity'}.to_json
  end
  
  file_id = params[:file_id]
  entity = params[:entity]
  
  if entity.to_s != "share" && entity.to_s != "private" then
    status 400
    return {'result' => -1, 'error_msg' => "Invaild entity: #{entity}"}.to_json
  end
  
  begin
      file = Files.find(file_id.to_i)
  rescue ActiveRecord::RecordNotFound => e
    content_type :json
    status 400
    return {'result' => -1, 'error_msg' => "File doesn't exists"}.to_json
  end
  users_a = []
  if entity.to_s == "share" then
    if params[:share_tenants].nil? then
      status 400
      return {'result' => -1, 'error_msg' => 'Missing required parameter: share_tenants'}.to_json
    end
    share_tenants = params[:share_tenants]
    array_share_tenant = share_tenants.split(",")
    array_share_tenant.each do |tenant|
      #根据tenant查询tenant中用户
      RestClient.post("http://172.17.10.199/cas-server/v1/getUsersByTenant/#{tenant}", {}, {:content_type => :json, :accept => :json}){ |response, request, result, &block| 
        array_user = JSON.parse(response.body)
        #为这些用户增加share记录
        array_user['users'].each do |user|
          file_share = FileShare.new
          file_share.file_id = file_id.to_i
          file_share.username = user['email']
          file_share.entity = entity.to_s
          file_share.tenant = tenant.to_i
          file_share.save
        end
	  }
    end
  elsif entity.to_s == "private" then
    if params[:share_tenants].nil? then
      array_file = FileShare.where("file_id=?", file_id.to_s)
      array_file.each do |file|
        file.destroy()
      end
    else
      share_tenants = params[:share_tenants]
      array_share_tenant = share_tenants.split(",")
      array_share_tenant.each do |tenant|
        array_file = FileShare.where("file_id=? and tenant=?", file_id.to_s, tenant.to_i)
        array_file.each do |file|
          file.destroy()
        end
      end
    end
  end
  status 200
  {'result' => 0}.to_json
end

