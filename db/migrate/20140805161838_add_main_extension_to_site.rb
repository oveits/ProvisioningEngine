class AddMainExtensionToSite < ActiveRecord::Migration
  def change
    add_column :sites, :mainextension, :string
  end
end
