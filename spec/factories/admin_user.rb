
  FactoryGirl.define do
    factory :admin_user do 
      email "admin@example.com"
      password "password"

      # from: http://stackoverflow.com/questions/7145256/find-or-create-record-through-factory-girl-association
      initialize_with { admin_user = AdminUser.find_or_create_by(email: email) 
			admin_user.update_attributes(password: password) 
			admin_user }
    end # factory :target do 
  end # FactoryGirl.define do
