class AddProvisionigobjectColumnToProvisionings < ActiveRecord::Migration
  def up
    change_table :provisionings do |t|
      t.references :provisioningobject, :polymorphic => true
    end
  end
  def down
    change_table :provisionings do |t|
      t.remove_references :provisioningobject, :polymorphic => true
    end
  end
end
