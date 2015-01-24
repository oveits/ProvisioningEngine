json.array!(@provisionings) do |provisioning|
  provisioning_wo_passwd = provisioning
  provisioning_wo_passwd.action = provisioning_wo_passwd.action.gsub(/(assw[^=]*=[ ]*)([^\r]*).*$/, '\1*******')
  provisioning_wo_passwd.status = provisioning_wo_passwd.status.gsub(/(assw[^=]*=[ ]*)([^\r]*).*$/, '\1*******')

  #json.extract! provisioning, :id, :action
  # replaced by (see http://stackoverflow.com/questions/23027644/how-to-extract-all-attributes-with-rails-jbuilder)
  json.merge! provisioning_wo_passwd.attributes

  json.url provisioning_url(provisioning, format: :json)
end
