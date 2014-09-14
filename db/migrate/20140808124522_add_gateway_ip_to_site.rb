class AddGatewayIpToSite < ActiveRecord::Migration
  def change
    add_column :sites, :gatewayIP, :string
  end
end
