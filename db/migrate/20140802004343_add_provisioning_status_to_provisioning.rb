class AddProvisioningStatusToProvisioning < ActiveRecord::Migration
  def change
    add_column :provisionings, :provisioning_status, :string
  end
end
