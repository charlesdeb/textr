# frozen_string_literal: true

class Chunk < ApplicationRecord
  validates_presence_of :size
  validates_presence_of :count
  validates_presence_of :token_ids
  validates_uniqueness_of :token_ids, scope: :language_id

  belongs_to :language

  # helper method for converting an array of token_ids back to an array of
  # readable text
  def to_token_texts
    Token.token_ids_to_token_texts(token_ids)
  end

  # Debugging way of seeing contents of chunks table with token_ids maped back to text
  # Chunk.all.map { |chunk| chunk.to_token_texts.join('') + "|     size: #{chunk.size} count: #{chunk.count}" }.sort
end
