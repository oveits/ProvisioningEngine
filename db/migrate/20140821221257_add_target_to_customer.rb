class AddTargetToCustomer < ActiveRecord::Migration
  def change
    add_reference :customers, :target, index: true
  end
end
