# frozen_string_literal: true

class Chunk < ApplicationRecord
  validates_presence_of :size
  validates_presence_of :count
  validates_presence_of :token_ids
  validates_uniqueness_of :token_ids, scope: :language_id

  belongs_to :language

  scope :exclude_candidate_token_ids, lambda { |token_ids, array_position|
    token_ids_list = token_ids.join(', ')
    where("token_ids[#{array_position}] NOT IN (#{token_ids_list})") unless token_ids.empty?
  }

  # helper method for converting an array of token_ids back to an array of
  # readable text
  def to_token_texts
    Token.token_ids_to_token_texts(token_ids)
  end

  # returns chunks that start with the given token ids
  #
  # @param token_ids [Array<Integer>]
  # @param language_id [Integer] Language tokens are for
  # @return [Array<Chunk>]
  #
  # We only analyse up to 8 tokens at a time
  def self.by_starting_tokens(token_ids, language_id)
    token_ids_where = []

    token_ids.each_with_index do |token_id, index|
      break if index > ChunkAnalyser::CHUNK_SIZE_RANGE.max

      # and build a where clause so that all the tokens in the array match.
      # Note: PostgreSQL arrays are 1-indexed and not 0-indexed
      token_ids_where << "token_ids[#{index + 1}] = #{token_id}"
    end
    token_ids_where = token_ids_where.join(' AND ')

    candidates = Chunk
                 .where("language_id = :language_id AND size >= :word_length AND #{token_ids_where}",
                        language_id: language_id, word_length: token_ids.size)
                 .limit(nil)
    # p token_ids
    # p token_ids_where
    # p candidates.all
    # p language_id
    # # p candidates.all.first.token_ids
    # # p candidates.count

    # candidates.all.each do |candidate|
    #   p candidate
    #   # p "#{candidate} #{candidate.token_ids}"
    #   puts "#{candidate.token_ids} #{candidate.to_token_texts}"
    # end
  end

  # Debugging way of seeing contents of chunks table with token_ids mapped back to text
  # Chunk.all.map { |chunk| chunk.to_token_texts.join('') + "|     size: #{chunk.size} count: #{chunk.count}" }.sort
end
