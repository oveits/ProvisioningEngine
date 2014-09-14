class AddCodeToSite < ActiveRecord::Migration
  def change
    add_column :sites, :code, :string
  end
end
