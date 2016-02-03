class AddJobIdToProvisionings < ActiveRecord::Migration
  def change
    add_column :provisionings, :job_id, :string
  end
end
