class AddAttemptsToProvisioning < ActiveRecord::Migration
  def change
    add_column :provisionings, :attempts, :integer
  end
end
