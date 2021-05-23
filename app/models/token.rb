# frozen_string_literal: true

# A token is either a single character (for by_letter analysis) eg a,b, ,!
# or a collection of one or more characters (for by_word analysis).  eg cat, hat, , I, !
class Token < ApplicationRecord
  validates :text, length: { minimum: 1 }
  validates_uniqueness_of :text, case_sensitive: false

  # Convert the text of text_message to an array of IDs in the tokens table
  # @param [String] message contains text to convert to tokens
  # @param [Symbol] strategy one of :by_letter, :by_word
  # @return [Array<Integer>] An array of token IDs from the tokens table
  def self.id_ise(message, strategy = nil)
    # ensure we are using a known analysis strategy
    validate_strategy(strategy)

    return [] if message.blank?

    # split the text into tokens according to the strategy
    token_texts = split_into_token_texts(message, strategy)
    # p "token_texts: #{token_texts}"

    # save any new tokens in the database for future reference
    save_token_texts(token_texts)

    # return the IDs of the tokens
    token_texts_to_token_ids(token_texts)
  end

  # splits text into tokens depending on the strategy
  # @param [String] text
  # @param [Symbol] strategy either :by_word or :by_letter
  # @return [Void]
  #
  # 'hey,  man!'  -> ["hey", ",", " ", "man", "!"]
  #
  # we could make this simpler just by breaking on spaces and ditching
  # punctuation eg 'hey, man!' -> ["hey", "man"]
  # We treat a single space as different to multiple spaces
  #
  # text_sample_tokens = text_sample.text
  #                                 .split(/\s|\p{Punct}/)
  #                                 .compact
  #                                 .reject(&:empty?)
  def self.split_into_token_texts(text, strategy = :by_word)
    # ensure we are using a known analysis strategy
    validate_strategy(strategy)

    # remove consecutive spaces and other guff
    text = text.squeeze(' !?')

    case strategy
    when :by_letter
      text.split('')
    when :by_word
      text.split(/(\s+)|(\p{Punct})/).compact.reject(&:empty?)
    end
  end

  # upserts the contents of token_texts
  # @param [Array] token_texts
  # @return [Void]
  def self.save_token_texts(token_texts)
    current_time = DateTime.now

    # strip out any duplicate tokens. Although insert_all will do this, it's
    # more efficient to do it in memory
    unique_token_texts = token_texts.uniq
    unique_token_texts_import = unique_token_texts.map do |the_token|
      { text: the_token,
        created_at: current_time, updated_at: current_time }
    end

    # Stick in the database
    Token.insert_all unique_token_texts_import
  end

  # converts an array of tokens in text form to their IDs
  # @param [Array<String>] token_texts
  # @return [Array<Integer>] ids of given token texts
  def self.token_texts_to_token_ids(token_texts)
    token_texts.map do |text|
      Token.where({ text: text }).first.id
    rescue NoMethodError
      raise StandardError, "Unknown token (#{text}). You may need to reanalyse the source text"
    end
  end

  # convert an array of token ids to an array of text tokens
  #
  # @param [Array<Integer>] token_ids
  # @return [Array<String>] texts of given token IDs
  def self.token_ids_to_token_texts(token_ids)
    token_ids.map do |token_id|
      Token.where({ id: token_id }).first.text
    rescue NoMethodError
      raise StandardError, "Unknown token id(#{token_id}). You may need to reanalyse the source text"
    end
  end

  # ensure strategy is :by_letter or :by_word or raise error
  # @param [Symbol]
  def self.validate_strategy(strategy)
    unless (strategy == :by_word) || (strategy == :by_letter)
      raise ArgumentError,
            "Invalid strategy :#{strategy} for Token.id_ise. Choose either :by_letter or :by_word"

    end
  end
end
