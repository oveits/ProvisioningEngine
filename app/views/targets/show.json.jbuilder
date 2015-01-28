#
# hide passwords:
#
target_wo_passwd = @target
target_wo_passwd.configuration = @target.configuration.gsub(/(assw[^=]*=[ ]*)([^\r]*).*$/, '\1*******') unless @target.configuration.nil?
#abort configuration_wo_passwd.inspect
#target_wo_passwd.configuration = configuration_wo_passwd
#abort target_wo_passwd.inspect

#json.extract! @target, :id, :name, :configuration, :created_at, :updated_at
json.merge! target_wo_passwd.attributes

