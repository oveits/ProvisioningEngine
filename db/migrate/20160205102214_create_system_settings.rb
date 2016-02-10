class CreateSystemSettings < ActiveRecord::Migration
  def change
    create_table :system_settings do |t|
      t.string :name
      t.string :value_type
      t.string :value_default
      t.string :value
      t.string :short_description
      t.text :description

      t.timestamps null: false
    end
  end
end
