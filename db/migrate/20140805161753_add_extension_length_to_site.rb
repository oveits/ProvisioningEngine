class AddExtensionLengthToSite < ActiveRecord::Migration
  def change
    add_column :sites, :extensionlength, :string
  end
end
