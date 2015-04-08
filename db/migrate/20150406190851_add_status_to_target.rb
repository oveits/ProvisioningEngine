class AddStatusToTarget < ActiveRecord::Migration
  def change
    add_column :targets, :status, :text
  end
end
