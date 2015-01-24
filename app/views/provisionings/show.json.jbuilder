#json.extract! @provisioning, :id, :action, :created_at, :updated_at
# replaced by (see http://stackoverflow.com/questions/23027644/how-to-extract-all-attributes-with-rails-jbuilder)
#json.merge! @provisioning.attributes
#{"id":521,"action":"action=Delete Customer, customerName=Microsoft, OSVIP = 192.168.112.140, OSVMgmtIP = 192.168.112.140, OSVSshPort = 22, XPRIP = 192.168.113.102, UCIP = 192.168.112.133, WebCDCIP = UNKNOWN, OSVauthUsername = srx, OSVauthPassword = 2GwN!gb4, OSVauthPasswordRoot = Asd123!., OSVauthPasswordSysad = Asd123!., XPRauthUsername =  administrator, XPRauthPassword =  Pa$$w0rd, UCauthUsername = Administrator@system, UCauthPassword =  Pa$$w0rd, FPAFOmit = true","created_at":"2015-01-23T09:25:00.743Z","updated_at":"2015-01-23T09:26:40.959Z","status":"finished successfully at 2015-01-23 10:26:40 +0100","customer_id":96,"site_id":null,"delayedjob_id":537,"attempts":1,"user_id":null}
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
provisioning_wo_passwd.action = @provisioning.action.gsub(/(assw[^=]*=[ ]*)([^\r]*).*$/, '\1*******')

json.merge! provisioning_wo_passwd.attributes

