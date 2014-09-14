class FixColumnName < ActiveRecord::Migration
  def change
    rename_column :sites, :code, :sitecode
  end
end
