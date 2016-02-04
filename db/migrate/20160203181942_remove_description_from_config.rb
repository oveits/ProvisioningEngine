class RemoveDescriptionFromConfig < ActiveRecord::Migration
  def change
    remove_column :configs, :description, :string
  end
end
