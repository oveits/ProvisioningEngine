#json.extract! @provisioning, :id, :action, :created_at, :updated_at
# replaced by (see http://stackoverflow.com/questions/23027644/how-to-extract-all-attributes-with-rails-jbuilder)
#json.merge! @provisioning.attributes
#json.id @provisioning.id
#json.action @provisioning.action
#json.created_at @provisioning.created_at
#json.updated_at @provisioning.updated_at
#json.status" @provisioning.status
#json.customer_id @provisioning.customer_id
#json.site_id @provisioning.site_id
#json.user_id @provisioning.user_id
#json.delayedjob_id @provisioning.delayedjob_id
#json.attempts @provisioning.attempts 


#
# hide passwords:
#
provisioning_wo_passwd = @provisioning
provisioning_wo_passwd.action = @provisioning.action.gsub(/(assw[^=]*=[ ]*)([^\r]*).*$/, '\1*******') unless @provisioning.action.nil?

json.merge! provisioning_wo_passwd.attributes

