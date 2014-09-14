class RemoveProvisioningStatusToProvisioning < ActiveRecord::Migration
  def change
    remove_column :provisionings, :provisioning_status, :string
  end
end
