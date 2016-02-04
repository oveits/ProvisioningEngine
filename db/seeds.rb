if AdminUser.count == 0
  AdminUser.create!([
    {email: "admin@example.com", encrypted_password: "$2a$10$lBmG9eNLLxS1GyCEBS6dcu/AtStbUdzmZKd2NN3k2tAkEAZWS8nyu", reset_password_token: nil, reset_password_sent_at: nil, remember_created_at: nil, sign_in_count: 1, current_sign_in_at: "2016-02-03 18:23:09", last_sign_in_at: "2016-02-03 18:23:09", current_sign_in_ip: "93.104.170.126", last_sign_in_ip: "93.104.170.126"}
  ])
end

if Config.where(name: "WEBPORTAL_SIMULATION_MODE").count == 0
  Config.create!([
    {name: "WEBPORTAL_SIMULATION_MODE", value_type: "boolean", value: "true", short_description: "Run the web portal in simulation (demo) mode (default: true)", description: "In simulation mode, the web portal runs in demo mode and no connection to a provisioning target is needed. This mode is intended to demonstrate the handling of the portal without the need to connect to an Apache Camel backend and target systems.", default_value: "true"}
  ])
else
  # keep value, but update the rest:
  Config.where(name: "WEBPORTAL_SIMULATION_MODE")[0].update_attributes(name: "WEBPORTAL_SIMULATION_MODE", value_type: "boolean", short_description: "Run the web portal in simulation (demo) mode (default: true)", description: "In simulation mode, the web portal runs in demo mode and no connection to a provisioning target is needed. This mode is intended to demonstrate the handling of the portal without the need to connect to an Apache Camel backend and target systems.", default_value: "true")
end  