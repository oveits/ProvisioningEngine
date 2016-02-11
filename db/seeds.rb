if AdminUser.count == 0
  AdminUser.create! :email => 'admin@example.com', :password => 'password', :password_confirmation => 'password'
end

if SystemSetting.where(name: "WEBPORTAL_SIMULATION_MODE").count == 0
  SystemSetting.create!([
    {name: "WEBPORTAL_SIMULATION_MODE", value_type: "boolean", value: "true", short_description: "Run the web portal in simulation (demo) mode (default: true)", description: "In simulation mode, the web portal runs in demo mode and no connection to a provisioning target is needed. This mode is intended to demonstrate the handling of the portal without the need to connect to an Apache Camel backend and target systems.", default_value: "true"}
  ])
else
  # keep value, but update the rest:
  SystemSetting.where(name: "WEBPORTAL_SIMULATION_MODE")[0].update_attributes(name: "WEBPORTAL_SIMULATION_MODE", value_type: "boolean", short_description: "Run the web portal in simulation (demo) mode (default: true)", description: "In simulation mode, the web portal runs in demo mode and no connection to a provisioning target is needed. This mode is intended to demonstrate the handling of the portal without the need to connect to an Apache Camel backend and target systems.", default_value: "true")
end  
