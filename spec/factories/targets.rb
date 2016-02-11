# spec/factories/customers.rb
# spec/factories/targets_private.rb
if SystemSetting.webportal_simulation_mode
  FactoryGirl.define do
    factory :target do 
      name "testtarget"
      factory :target_Environment1_V8 do
        name "Environment1_V8"
        configuration "OSVIP=1.1.1.1,XPRIP=2.2.2.2,UCIP=3.3.3.3,OSVauthUsername=srx,OSVauthPassword=mypassword,OSVauthPasswordRoot=mypassword,OSVauthPasswordSysad=mypassword,XPRauthUsername=Administrator,XPRauthPassword=mypassword,UCauthUsername=Administrator@system,UCauthPassword=mypassword"
      end
    
      factory :target_Environment2_V7R1 do
        name "Environment2_V7R1"
        configuration "OSVIP=1.1.1.1,XPRIP=2.2.2.2,UCIP=3.3.3.3,OSVauthUsername=srx,OSVauthPassword=mypassword,OSVauthPasswordRoot=mypassword,OSVauthPasswordSysad=mypassword,XPRauthUsername=Administrator,XPRauthPassword=mypassword,UCauthUsername=Administrator@system,UCauthPassword=mypassword"
      end
    end # factory :target do 
  end # FactoryGirl.define do
end # if SystemSetting.webportal_simulation_mode

