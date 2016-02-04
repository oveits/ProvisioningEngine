class AddDefaultValueToConfig < ActiveRecord::Migration
  def change
    add_column :configs, :default_value, :string
  end
end
