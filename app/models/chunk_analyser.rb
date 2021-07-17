# frozen_string_literal: true

# Used for analysting text_messages using a chunk algorithm
class ChunkAnalyser
  CHUNK_SIZE_RANGE = (2..8)

  def initialize(text_message)
    @text_message = text_message
  end

  # Count the letters and tokens in the text message to be used for prediction
  # @return [Hash] with information about how the analysis went for
  #                different strategies
  def analyse
    output = {}
    # %i[by_letter by_word].each do |strategy|
    %i[by_word].each do |strategy|
      start_time = Time.now
      token_ids = Token.id_ise(@text_message.text, strategy)
      analyse_by_tokens(token_ids)
      output[strategy] = { chunks: token_ids.length,
                           seconds_elapsed: Time.now - start_time }
    end

    output
  end

  # Count the number of times different chunk of token ids appear in token_ids
  #
  # @param [Array] text message once converted to token ids
  # @return [Void]
  def analyse_by_tokens(token_ids)
    CHUNK_SIZE_RANGE.each do |chunk_size|
      break if chunk_size > token_ids.length

      count_chunks(token_ids, chunk_size)
    end
  end

  # Count the times chunks of the given chunk_size appear in token_ids
  #
  # @param [Array] text message once converted to token ids
  # @param [Integer] number of consecutive tokens to count
  # @return [Void]
  def count_chunks(token_ids, chunk_size)
    chunks_hash = build_chunks_hash(token_ids, chunk_size)
    upsert_chunks_hash(chunks_hash, chunk_size)
  end

  # Build a hash of chunks of tokens with the number of times the chunk appeared in token_ids
  #
  # @param [Array]   text message once converted to token ids
  # @param [Integer] number of consecutive tokens to count
  # @return [Hash]   a hash of chunk_size tokens with the count of how many
  #                  times those tokens appeared in token_ids
  def build_chunks_hash(token_ids, chunk_size)
    hash = Hash.new(0)
    limit = token_ids.size - chunk_size
    (0..limit).each do |i|
      # iterate through the sentence chunks one token at a time
      # chunk_text = token_ids[i, chunk_size].join
      chunk_text = token_ids[i, chunk_size]
      # increment the count of the chunk we just found
      # use fetch to retrieve hash values if the array is a key
      # h = {[1]=> 2}
      # h.fetch([1])   #  => 2
      hash[chunk_text] += 1
    end
    hash
  end

  def upsert_chunks_hash(chunks_hash, chunk_size) # rubocop:disable Metrics/MethodLength
    current_time = DateTime.now
    import_array = []
    chunks_hash.each do |token_ids, count|
      # find an existing chunk with the same language, chunk_size and token_ids
      existing_chunk = Chunk.where(
        {
          language_id: @text_message.language_id,
          size: chunk_size,
          token_ids: token_ids
        }
      ).first

      # byebug

      # p @text_message
      # puts 'existing chunk from where:'
      # p existing_chunk.first
      # puts 'existing fist chunk from database:'
      # p Chunk.first

      import_hash = {
        token_ids: token_ids,
        size: chunk_size,
        count: count + (existing_chunk.nil? ? 0 : existing_chunk.count),
        language_id: @text_message.language_id,
        created_at: current_time,
        updated_at: current_time
      }
      import_array << import_hash
    end
    Chunk.upsert_all import_array, unique_by: %i[language_id token_ids]
  end
end
