class AddAreaCodeToSite < ActiveRecord::Migration
  def change
    add_column :sites, :areacode, :string
  end
end
