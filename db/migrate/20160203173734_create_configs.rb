class CreateConfigs < ActiveRecord::Migration
  def change
    create_table :configs do |t|
      t.string :name
      t.string :value_type
      t.string :value

      t.timestamps null: false
    end
  end
end
