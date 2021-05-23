# frozen_string_literal: true

# Used for suggesting words based to a user
class Suggester
  def initialize(suggestion_params)
    @text = suggestion_params[:text]
    @language_id = suggestion_params[:language_id].to_i
    @show_analysis = (suggestion_params[:show_analysis] == 'true')
  end

  # Returns the most likely candidate tokens to come after the curent
  # text, optionally with analysis
  #
  # @return [Hash] A fairly complex hash object like this:
  #   { candidates: [
  #     { token_text: 'the', probability: 0.75, chunk_size: 6 },
  #     { token_text: 'a', probability: 0.15, chunk_size: 4 },
  #     { token_text: 'this', probability: 0.05, chunk_size: 4 }
  #   ],
  #     analysis: [
  #       { chunk_size: 6,
  #         chunk: 'The cat in ', candidate_token_texts: [
  #           { token_text: 'the', probability: 0.75 },
  #           { token_text: 'a', probability: 0.15 },
  #           { token_text: 'this', probability: 0.05 }
  #         ] },
  #       { chunk_size: 5,
  #         chunk: ' cat in ', candidate_token_texts: [
  #           { token_text: 'the', probability: 0.75 },
  #           { token_text: 'a', probability: 0.15 },
  #           { token_text: 'this', probability: 0.05 }
  #         ] },
  #       { chunk_size: 4,
  #         chunk: 'cat in ', candidate_token_texts: [
  #           { token_text: 'the', probability: 0.75 },
  #           { token_text: 'a', probability: 0.15 },
  #           { token_text: 'this', probability: 0.05 }
  #         ] }
  #     ] }
  def suggest
    return { candidates: [] } if @text.empty?

    current_word = find_current_word
    prior_tokens = find_prior_token_ids

    if prior_tokens
      suggestions_by_current_word_and_prior_tokens(current_word, prior_tokens)
    else
      suggestions_by_current_word(current_word)
    end
  end

  # Finds the most recently typed word in @text or nil
  # @return [String] nil if the user has just typed a space
  def find_current_word
    Token.split_into_token_texts(@text, :by_word)[-1]
  end

  # Finds the tokens in up until the last word @text
  # @return [Array<Integer>] nil if the user is entering their first word
  def find_prior_token_ids
    token_ids = Token.id_ise(@text, :by_word)[0..-2]
    token_ids.empty? ? nil : token_ids
  end

  # Finds suggestions of completion words based solely on the current word
  # @param current_word [String] The word the user is currently typing
  # @return [Array<Hash{token_text=>String, probability=>Float, chunk_size=>Integer}>]
  def suggestions_by_current_word(current_word)
    # p "current_word: #{current_word}"
    token_ids = Token.id_ise(current_word, :by_letter)
    # p "token_ids: #{token_ids}"

    candidates = Chunk.by_starting_tokens(token_ids, @language_id)

    suggestions = {}
    suggestions[:candidates] = []
    suggestions[:analysis] = [] if @show_analysis

    suggestions
  end

  #   token_ids_where = []

  #   # grab all but the first token in the chunk
  #   token_ids.each_with_index do |token_id, index|
  #     # and build a where clause so that all the tokens in the array match.
  #     # Note: PostgreSQL arrays are 1-indexed and not 0-indexed
  #     token_ids_where << "token_ids[#{index + 1}] = #{token_id}"
  #   end
  #   token_ids_where = token_ids_where.join(' AND ')

  #   candidates = Chunk
  #                .where("language_id = :language_id AND size >= :word_length AND #{token_ids_where}",
  #                       language_id: @language_id, word_length: token_ids.size)
  #                .limit(nil)
  #   # p token_ids
  #   # p token_ids_where
  #   # p candidates.all
  #   # p candidates.all.first.token_ids
  #   # p candidates.count

  #   candidates.all.each do |candidate|
  #     p candidate
  #     # p "#{candidate} #{candidate.token_ids}"
  #     puts "#{candidate.token_ids} #{candidate.to_token_texts}"
  #   end
  # end

  # Finds candidate completion words based on the current word and priorr tokens
  # @param current_word [String] The word the user is currently typing
  # @param prior_token_ids [Array<Integer>] IDs of the tokens for the words the user typed before the current word
  # @return [Array<Hash{token_text=>String, probability=>Float, chunk_size=>Integer}>]
  def suggestions_by_current_word_and_prior_tokens(current_word, prior_token_ids); end

  # Finds candidate completion words based on the current word and priorr tokens
  # @param token_ids [Array<Integer>] IDs of the tokens for the words the user typed before the current word
  # @return [Array<Hash{token_text=>String, probability=>Float, chunk_size=>Integer}>]
  def chunks_by_starting_tokens(token_ids); end
end
