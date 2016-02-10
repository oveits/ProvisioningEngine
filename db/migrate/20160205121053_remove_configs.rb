class RemoveConfigs < ActiveRecord::Migration
  def change
    drop_table :configs
  end
end
