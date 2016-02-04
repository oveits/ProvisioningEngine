class AddShortDescriptionToConfig < ActiveRecord::Migration
  def change
    add_column :configs, :short_description, :string
  end
end
