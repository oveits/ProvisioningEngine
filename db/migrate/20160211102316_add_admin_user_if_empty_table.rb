class AddAdminUserIfEmptyTable < ActiveRecord::Migration
  def change
    if AdminUser.count == 0
      AdminUser.create! :email => 'admin@example.com', :password => 'password', :password_confirmation => 'password'
    end
  end
end
