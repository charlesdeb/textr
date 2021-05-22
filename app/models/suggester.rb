# frozen_string_literal: true

# Used for suggesting words based to a user
class Suggester
  def initialize(suggestion_params)
    @text = suggestion_params[:text]
    @language_id = suggestion_params[:language_id]
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
    token_texts = Token.id_ise(@text, :by_word)[0..-2]
    token_texts.empty? ? nil : token_texts
  end

  # Finds candidate completion words based solely on the current word
  # @return [Array<Hash{token_text=>String, probability=>Float, chunk_size=>Integer}>]
  def suggestions_by_current_word(current_word); end

  # Finds candidate completion words based on the current word and priorr tokens
  # @return [Array<Hash{token_text=>String, probability=>Float, chunk_size=>Integer}>]
  def suggestions_by_current_word_and_prior_tokens(current_word, prior_tokens); end
end
