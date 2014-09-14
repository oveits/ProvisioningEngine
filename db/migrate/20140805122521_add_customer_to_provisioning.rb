class AddCustomerToProvisioning < ActiveRecord::Migration
  def change
    add_reference :provisionings, :customer, index: true
  end
end
