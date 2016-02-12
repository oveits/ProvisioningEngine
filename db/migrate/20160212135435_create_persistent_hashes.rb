class CreatePersistentHashes < ActiveRecord::Migration
  def change
    create_table :persistent_hashes do |t|
      t.string :name
      t.text :value

      t.timestamps null: false
    end
  end
end
