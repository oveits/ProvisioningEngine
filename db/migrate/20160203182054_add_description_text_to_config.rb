class AddDescriptionTextToConfig < ActiveRecord::Migration
  def change
    add_column :configs, :description, :text
  end
end
