class CreateTargets < ActiveRecord::Migration
  def change
    create_table :targets do |t|
      t.string :name
      t.text :configuration

      t.timestamps
    end
  end
end
