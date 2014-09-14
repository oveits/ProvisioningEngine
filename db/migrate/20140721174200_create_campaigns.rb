class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.string :name
      t.belongs_to :account, index: true

      t.timestamps
    end
  end
end
