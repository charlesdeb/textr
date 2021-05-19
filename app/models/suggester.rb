# frozen_string_literal: true

# Used for suggesting words based to a user
class Suggester
  def initialize(suggestion_params)
    @text_message = suggestion_params[:text_message]
    @language_id = suggestion_params[:language_id]
    @show_analysis = (suggestion_params[:show_analysis] == 'true')
  end

  # Returns the most likely candidate tokens to come after the curent
  # text_message, optionally with analysis
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
    return { candidates: [] } if @text_message.empty?

    current_word = find_current_word
    prior_tokens = find_prior_tokens

    if find_prior_tokens
      candidates_by_current_word_and_tokens(current_word, prior_tokens)
    else
      candidates_by_current_word(current_word)
    end
  end

  # Finds the most recently typed word in @text_message or nil
  # @return [String] nil if the user has just typed a space
  def find_current_word; end

  # Finds the tokens in up until the last word @text_message
  # @return [Array<Token>] nil if the user is entering their first word
  def find_prior_tokens; end

  # Finds candidate completion words based solely on the current word
  # @return [Array<Hash{token_text=>String, probability=>Float, chunk_size=>Integer}>]
  def candidates_by_current_word(current_word); end

  # Finds candidate completion words based on the current word and priorr tokens
  # @return [Array<Hash{token_text=>String, probability=>Float, chunk_size=>Integer}>]
  def candidates_by_current_word_and_tokens(current_word, prior_tokens); end
end
