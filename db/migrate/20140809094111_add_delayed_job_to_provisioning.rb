class AddDelayedJobToProvisioning < ActiveRecord::Migration
  def change
    add_reference :provisionings, :delayedjob, index: true
  end
end

