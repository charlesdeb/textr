# frozen_string_literal: true

# Used for suggesting words based to a user
class Suggester
  # Maximum number of suggestions to show the user
  MAX_SUGGESTIONS = 5

  def initialize(suggestion_params)
    @text = suggestion_params[:text]
    @language_id = suggestion_params[:language_id].to_i
    @show_analysis = (suggestion_params[:show_analysis] == 'true')
  end

  # Returns the most likely candidate tokens to come after the curent
  # text, optionally with analysis
  #
  # @return [Hash] See get_suggestions for details
  def suggest
    if @text.strip.empty?
      output = { candidates: [] }
      output[:analysis] = 'No text provided' if @show_analysis
      return output
    end

    current_word = find_current_word
    # possible_token_ids = get_possible_token_ids(current_word)
    prior_token_ids = find_prior_token_ids

    chunk_candidates = get_chunk_candidates(prior_token_ids, current_word)

    build_suggestions(chunk_candidates)
  end

  # Finds the most recently typed word in @text or nil
  #
  # @return [String] nil if the user has just typed a space
  def find_current_word
    Token.split_into_token_texts(@text, :by_word)[-1]
  end

  # Returns token IDs of Tokens that could match the current word
  # @param current_word [String] the latest word the user has typed
  #
  # @return [Array<Integer>] IDs of tokens that could match the word the user is typing
  #
  # Will return [] if there is no match or current word is empty
  def get_possible_token_ids(current_word)
    return [] if current_word.blank?

    text = Token.arel_table[:text]
    Token
      .select('id')
      .where(text.matches("#{current_word}%"))
      .map(&:id)
  end

  # Finds the last 8 token IDs of the tokens in @text
  #
  # @return [Array<Integer>] nil if the user is entering their first word
  #
  # Creates tokens if needed for any new words
  def find_prior_token_ids
    # get the tokens ids except for the last token
    token_ids = Token.id_ise(@text, :by_word)[0..-2]

    # return (at most) the most recent 8 of those tokens
    token_ids = token_ids[(token_ids.length > 8 ? -8 : (-1 - (token_ids.length - 1)))..]

    token_ids.empty? ? nil : token_ids
  end

  # Returns best chunk candidates that match current user input
  #
  # @param prior_token_ids [Array<Integer>] array of token IDs that have been
  #                                         entered so far
  # @param current_word [String] text of the word the user is currently typing
  #
  # @return [Hash] a hash containing word suggestions, and (optionally) some
  #                analysis
  def get_chunk_candidates(prior_token_ids, current_word); end

  # Returns a hash of suggestions and (optionally) analysis from the best
  # chunk candidates
  #
  # @param [Array<Chunk>] chunks that best match the users input
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
  def build_suggestions(chunk_candidates); end

  # Returns the actual suggestions of possible token completions with probabilities
  # @param prior_token_ids [Array<Token>] Tokens representing what the user has already entered before the current word
  # @param possible_token_ids [Array<Token>] Tokens that could match the last word user
  #
  def get_suggestions(_prior_token_ids, _possible_token_ids)
    # { candidates: [{ token_text: 'stuff', probability: 0.5 }] }
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

  # Finds candidate completion words based on the current word and priorr tokens
  # @param current_word [String] The word the user is currently typing
  # @param prior_token_ids [Array<Integer>] IDs of the tokens for the words the user typed before the current word
  # @return [Array<Hash{token_text=>String, probability=>Float, chunk_size=>Integer}>]
  def suggestions_by_current_word_and_prior_token_ids(current_word, prior_token_ids); end

  # Finds candidate completion words based on the current word and priorr tokens
  # @param token_ids [Array<Integer>] IDs of the tokens for the words the user typed before the current word
  # @return [Array<Hash{token_text=>String, probability=>Float, chunk_size=>Integer}>]
  def chunks_by_starting_tokens(token_ids); end
end
