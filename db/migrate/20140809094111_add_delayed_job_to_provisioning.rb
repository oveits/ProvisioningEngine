class AddDelayedJobToProvisioning < ActiveRecord::Migration
  def change
    add_column :provisionings, :delayedjob, :reference
  end
end
