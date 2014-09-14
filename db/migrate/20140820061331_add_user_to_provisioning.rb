class AddUserToProvisioning < ActiveRecord::Migration
  def change
    add_reference :provisionings, :user, index: true
  end
end
