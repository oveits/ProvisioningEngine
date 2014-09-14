class AddStatusToProvisioning < ActiveRecord::Migration
  def change
    add_column :provisionings, :status, :string
  end
end
