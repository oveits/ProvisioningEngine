class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.belongs_to :site, index: true
      t.string :extension
      t.string :givenname
      t.string :familyname
      t.string :email

      t.timestamps
    end
  end
end
