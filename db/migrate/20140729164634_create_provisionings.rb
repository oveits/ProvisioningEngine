class CreateProvisionings < ActiveRecord::Migration
  def change
    create_table :provisionings do |t|
      t.string :action

      t.timestamps
    end
  end
end
