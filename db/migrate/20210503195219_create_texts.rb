class CreateTexts < ActiveRecord::Migration[6.1]
  def change
    create_table :texts do |t|
      t.text :text
      t.references :language, null: false, foreign_key: true

      t.timestamps
    end
  end
end
