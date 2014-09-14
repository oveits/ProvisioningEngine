class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites do |t|
      t.string :name
      t.belongs_to :customer, index: true

      t.timestamps
    end
  end
end
