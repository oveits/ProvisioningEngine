class AddSiteToProvisioning < ActiveRecord::Migration
  def change
    add_reference :provisionings, :site, index: true
  end
end
