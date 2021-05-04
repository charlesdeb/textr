# frozen_string_literal: true

class EnsureLanguagesUnique < ActiveRecord::Migration[6.1]
  def change
    add_index(:languages, :language, unique: true)
  end
end
