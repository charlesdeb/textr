class RenameTextToTextMessage < ActiveRecord::Migration[6.1]
  def change
    rename_table :texts, :text_messages
  end
end
