class AddCountryCodeToSite < ActiveRecord::Migration
  def change
    add_column :sites, :countrycode, :string
  end
end
