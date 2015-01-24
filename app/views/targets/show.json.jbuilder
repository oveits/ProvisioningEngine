#
# hide passwords:
#
target_wo_passwd = @target
configuration_wo_passwd = @target.configuration.gsub(/(assw[^=]*=[ ]*)([^\r]*).*$/, '\1*******')
#abort configuration_wo_passwd.inspect
target_wo_passwd.configuration = configuration_wo_passwd
#abort target_wo_passwd.inspect

#json.extract! @target, :id, :name, :configuration, :created_at, :updated_at
json.merge! target_wo_passwd.attributes

