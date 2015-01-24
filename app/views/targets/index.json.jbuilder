json.array!(@targets) do |target|
  target_wo_passwd = target
  target_wo_passwd.configuration = target_wo_passwd.configuration.gsub(/(assw[^=]*=[ ]*)([^\r]*).*$/, '\1*******')
  #target_wo_passwd.status = target_wo_passwd.status.gsub(/(assw[^=]*=[ ]*)([^\r]*).*$/, '\1*******') unless target_wo_passwd.status.nil?

  #json.extract! target, :id, :action
  # replaced by (see http://stackoverflow.com/questions/23027644/how-to-extract-all-attributes-with-rails-jbuilder)
  json.merge! target_wo_passwd.attributes

  json.url target_url(target, format: :json)
end
