class ChangeStatusColumnFromStringToText < ActiveRecord::Migration
  def up
    change_column :provisionings, :status, :text, limit: nil
  end
  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :provisionings, :status, :string
  end
end
