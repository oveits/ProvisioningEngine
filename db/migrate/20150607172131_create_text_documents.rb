class CreateTextDocuments < ActiveRecord::Migration
  def change
    create_table :text_documents do |t|
      t.text :identifierhash
      t.text :content

      t.timestamps
    end
  end
end
