class AddStatusToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :status, :string
  end
end
