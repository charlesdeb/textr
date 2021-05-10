class CreateTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :tokens do |t|
      t.string :text

      t.timestamps
    end
    add_index :tokens, :text, unique: true
  end
end
