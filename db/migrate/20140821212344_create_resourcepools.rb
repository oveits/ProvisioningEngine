class CreateResourcepools < ActiveRecord::Migration
  def change
    create_table :resourcepools do |t|
      t.string :name
      t.string :resource

      t.timestamps
    end
  end
end
