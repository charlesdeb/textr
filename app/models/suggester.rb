# frozen_string_literal: true

# require 'app/refinements/string.rb'
require 'string'

# Used for suggesting words based to a user
class Suggester # rubocop:disable Metrics/ClassLength
  # Maximum number of suggestions to show the user
  MAX_SUGGESTIONS = 5

  # attr_accessor :text, :language_id, :show_analysis

  def initialize(suggestion_params)
    @text = suggestion_params[:text]
    @language_id = suggestion_params[:language_id].to_i
    @show_analysis = (suggestion_params[:show_analysis] == 'true')
  end

  # Returns the most likely candidate tokens to come after the curent
  # text, optionally with analysis
  #
  # @return [Hash] See build_suggestions for details
  def suggest
    return { candidates: [] } if @text.strip.empty?

    current_word = find_current_word
    # possible_token_ids = get_possible_token_ids(current_word)
    prior_token_ids = find_prior_token_ids

    chunk_candidates = get_candidate_chunks(prior_token_ids, current_word)

    build_suggestions(chunk_candidates)
  end

  # Finds the most recently typed word in @text or nil
  #
  # @return [String] nil if the user has just typed a space
  def find_current_word
    result = Token.split_into_token_texts(@text, :by_word)[-1]

    (result == ' ' ? nil : result)
  end

  # OBSOLETE
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

  # add the .punctuation? and .whitespace? methods
  using Refinements

  # Finds the last 8 token IDs of the tokens in @text
  #
  # @return [Array<Integer>] nil if the user is entering their first word
  #
  # Creates tokens if needed for any new words. If the user is entering spaces
  # then this counts as the space token
  def find_prior_token_ids
    max_tokens_to_return = ChunkAnalyser::CHUNK_SIZE_RANGE.max - 1

    # get the token ids
    prior_token_text = Token.split_into_token_texts(@text)

    # remove last piece of text, unless it's a space or punctuation
    last_token_text = prior_token_text[-1]
    prior_token_text = prior_token_text[0..-2] unless last_token_text.punctuation? || last_token_text.whitespace?

    # add any new tokens just found to the database - including duff tokens
    # with typos in it - since our algorithm only works with IDs
    prior_token_text = prior_token_text.join
    token_ids = Token.id_ise(prior_token_text, :by_word)

    # return (at most) the most recent 8 of those tokens
    # TODO: refactor to make it simpler to understand
    token_ids[(token_ids.length > max_tokens_to_return ? -max_tokens_to_return : (-1 - (token_ids.length - 1)))..]
  end

  # Returns best chunk candidates that match current user input
  #
  # @param prior_token_ids [Array<Integer>] array of token IDs that have been
  #                                         entered so far
  # @param current_word [String] text of the word the user is currently typing
  # @param candidate_token_ids [Array<Int>] candidate tokens that have already been found.
  #                                      It is empty for the first call, but should get
  #                                      longer with recursive calls
  #
  # @return [Array<Chunk>] I think just an array of Chunks that are candidates - not an ActiveRelation
  #
  # Get the candidate chunks for the current prior_token_ids, current_word -
  # and if we can't get MAX_SUGGESTIONS of candidates, then lose the current_word
  # and keep looking
  def get_candidate_chunks(prior_token_ids, current_word)
    candidate_token_ids = []
    # Get chunk candidates that match the prior tokens with the current word
    candidate_chunks = get_chunks_by_prior_tokens_and_current_word(
      prior_token_ids, current_word, candidate_token_ids
    )

    # get the token ids from those chunks
    candidate_token_ids += get_token_id_candidates_from_chunks(candidate_chunks.to_a)

    # If we got our MAX_SUGGESTIONS or we have looked at all the prior tokens, then we're done
    return candidate_chunks if candidate_token_ids.size == MAX_SUGGESTIONS

    # get more chunks but without using the current_word
    candidate_chunks + get_chunks_by_prior_tokens_only(prior_token_ids,
                                                       candidate_token_ids)
  end

  # Returns chunks candidates that match current user input ordered by occurrence
  #
  # @param prior_token_ids [Array<Integer>] array of token IDs that have been
  #                                         entered so far
  # @param current_word [String]            text of the word the user is currently typing
  # @param candidate_token_ids [Array<Int>] candidate token IDs that have already been found
  # @return [Array<Chunk>]                  chunks that match the search parameters
  #
  # Returns empty array if the current word doesn't match any known tokens
  # TODO: refactor this
  def get_chunks_by_prior_tokens_and_current_word(prior_token_ids, current_word, candidate_token_ids = []) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    # find all the possible tokens that start with the current_word
    # TODO: we only really need to calculate this once, not each time this is
    # called
    candidate_tokens_for_current_word = Token.starting_with(current_word)

    return Chunk.none if candidate_tokens_for_current_word.empty?

    candidate_token_ids_for_current_word = candidate_tokens_for_current_word.to_a.map(&:id)

    token_ids_where = candidate_token_ids_for_current_word.map do |token_id|
      "token_ids = ARRAY#{prior_token_ids + [token_id]}"
    end
    token_ids_where = token_ids_where.join(' OR ')

    token_ids_where = " AND (#{token_ids_where} )" unless token_ids_where.blank?

    candidate_chunks = Chunk.where("language_id = :language_id #{token_ids_where}",
                                   language_id: @language_id)
                            .exclude_candidate_token_ids(candidate_token_ids, prior_token_ids.length + 1)
                            .limit(MAX_SUGGESTIONS - candidate_token_ids.size)
                            .order(count: :desc).to_a

    # Add new candidate tokens to the list
    candidate_token_ids += get_token_id_candidates_from_chunks(candidate_chunks)

    # If we got our MAX_SUGGESTIONS or we're out of prior_tokens, then we're done
    return candidate_chunks if candidate_token_ids.size == MAX_SUGGESTIONS || prior_token_ids.size.zero?

    candidate_chunks + get_chunks_by_prior_tokens_and_current_word(prior_token_ids[1..],
                                                                   current_word,
                                                                   candidate_token_ids)
  end

  # Returns chunks candidates that match current user input
  #
  # @param prior_token_ids [Array<Integer>] array of token IDs that have been
  #                                         entered so far
  # @param candidate_token_ids [Array<Int>] candidate tokens that have already been found
  #
  # @return [Array<Chunk>]                  chunks that match the search parameters
  #
  # Returns empty array if no prior tokens match any chunks (or if there are
  # no prior tokens)
  def get_chunks_by_prior_tokens_only(prior_token_ids, candidate_token_ids = []) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    return Chunk.none if prior_token_ids.empty?

    token_ids_where = prior_token_ids.map.with_index do |token_id, index|
      "token_ids[#{index + 1}] = #{token_id}"
    end

    token_ids_where = " AND #{token_ids_where.join(' AND ')}" unless token_ids_where.empty?

    candidate_chunks = Chunk.where("language_id = :language_id AND size = :size #{token_ids_where}",
                                   language_id: @language_id,
                                   size: prior_token_ids.length + 1)
                            .exclude_candidate_token_ids(candidate_token_ids, prior_token_ids.length + 1)
                            .limit(MAX_SUGGESTIONS - candidate_token_ids.size)
                            .order(count: :desc).to_a
    # Add new candidate tokens to the list
    candidate_token_ids += get_token_id_candidates_from_chunks(candidate_chunks)

    # If we got our MAX_SUGGESTIONS or we're out of prior_tokens, then we're done
    return candidate_chunks if candidate_token_ids.size == MAX_SUGGESTIONS || prior_token_ids.size.zero?

    candidate_chunks + get_chunks_by_prior_tokens_only(prior_token_ids[1..],
                                                       candidate_token_ids)
  end

  # Returns an array of final token IDs from each of the chunk_candidates
  # @param chunk_candidates [Array<Chunk>] Chunk candidates
  #
  # @return [Array<Integer>]
  def get_token_id_candidates_from_chunks(chunk_candidates)
    chunk_candidates.map { |chunk| chunk.token_ids[chunk.size - 1] }
  end

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
  def build_suggestions(chunk_candidates)
    candidates_array = chunk_candidates.map do |chunk|
      token_id = chunk.token_ids[chunk.size - 1]
      text = Token.find(token_id).text
      { token_text: text, chunk_size: chunk.size, count: chunk.count }
    end

    { candidates: candidates_array }
  end
end
