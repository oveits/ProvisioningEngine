class AddLocalOfficeCodeToSite < ActiveRecord::Migration
  def change
    add_column :sites, :localofficecode, :string
  end
end
