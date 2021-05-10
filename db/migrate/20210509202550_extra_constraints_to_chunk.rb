# frozen_string_literal: true

# migration
class ExtraConstraintsToChunk < ActiveRecord::Migration[6.1]
  def change
    change_column_null :chunks, :size, false
    change_column_null :chunks, :count, false
    change_column_null :chunks, :token_ids, false
    change_column_default :chunks, :token_ids, nil

    add_index :chunks, %i[language_id token_ids], unique: true
  end
end
