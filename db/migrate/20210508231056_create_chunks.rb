# frozen_string_literal: true

# migration
class CreateChunks < ActiveRecord::Migration[6.1]
  def change
    create_table :chunks do |t|
      t.integer :size
      t.integer :count
      t.references :language, null: false, foreign_key: true
      t.integer :token_ids, array: true, default: []

      t.timestamps
    end
    add_index :chunks, :size
    add_index :chunks, :token_ids
  end
end
