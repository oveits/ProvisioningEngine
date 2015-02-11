class ChangeActionColumnFromStringToText < ActiveRecord::Migration
  def up
    change_column :provisionings, :action, :text, limit: nil
  end
  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :provisionings, :action, :string
  end
end

