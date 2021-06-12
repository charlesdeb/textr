# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Chunk, type: :model do # rubocop:disable Metrics/BlockLength
  describe 'validations' do
    it { should validate_presence_of(:size) }
    it { should validate_presence_of(:count) }
    it { should validate_presence_of(:token_ids) }
    it { should belong_to(:language) }

    subject { create :chunk }

    it { should validate_uniqueness_of(:token_ids).scoped_to(:language_id) }

    skip 'ensures unique language and token_ids' do
      # this is done by the should validate_uniqueness_of macro above
      language = Language.create(language: 'klingon')
      # language = Language.new(language: 'KLINGON')

      Chunk.create({ size: 2, count: 1, token_ids: [1, 2], language_id: language.id })

      not_dupe_chunk = Chunk.new({ size: 2, count: 1, token_ids: [1, 3], language_id: language.id })
      expect(not_dupe_chunk).to be_valid
      not_dupe_chunk.save

      dupe_chunk = Chunk.new({ size: 2, count: 1, token_ids: [1, 2], language_id: language.id })
      expect(dupe_chunk).to_not be_valid
    end
  end

  describe '#chunks_by_starting_tokens' do
    let(:language) { create(:language, language: 'Klingon') }

    it 'finds all the chunks without punctuation that start with these tokens' do
      Token.create!({ id: 1, text: 'c' })
      Token.create!({ id: 2, text: 'a' })
      Token.create!({ id: 3, text: 't' })
      Token.create!({ id: 4, text: 'h' })
      # Token.create!({ id: 5, text: 'e' })
      # Token.create!({ id: 6, text: ' ' })

      ## 2 x ca, 4 x cat, 4 x cath, 1 x c_the, 1 x cat_, 1 x cath_
      # texts = %w[ca ca cat cat cat cat cath cath cath cath 'c the']
      texts = %w[ca cat cath cath]
      # texts = ['ca', 'ca',
      #          'cat', 'cat', 'cat', 'cat',
      #          'cath', 'cath', 'cath', 'cath',
      #          'c the', 'cat ', 'cath ']
      texts.each do |text|
        text_message = create(:text_message, { text: text, language: language })
        token_ids = Token.id_ise(text, :by_letter)
        analyser = ChunkAnalyser.new(text_message)
        # just put single character tokens in the chunks table
        analyser.analyse_by_tokens(token_ids)
      end

      puts "TextMessage.count: #{TextMessage.count}"

      puts "Chunk.count: #{Chunk.count}"
      puts 'Chunk.all:'
      # Chunk.all.each do |chunk|
      #   p chunk
      #   # p "#{chunk} #{chunk.token_ids}"
      #   puts "#{chunk.token_ids} #{chunk.to_token_texts}"
      # end

      token_ids = [1, 2] # current word is 'ca'

      Chunk.by_starting_tokens(token_ids, language.id)

      # current_word = 'ca'
      # params[:text] = current_word
      # suggester = Suggester.new(params)

      # suggestions = suggester.suggestions_by_current_word(current_word)
      # expect(sugges)
    end

    it 'sets probabilties properly'
  end

  describe '#by_starting_token_ids' do
    let(:prior_token_ids) { [1, 2, 3] }
    let!(:chunk) { create(:chunk, token_ids: [1, 2, 3, 4]) }

    it 'returns empty relation if there are no prior_token_ids' do
      prior_token_ids = []
      expect(Chunk.by_starting_token_ids(prior_token_ids).count).to eq(0)
    end

    it 'returns empty relation if there are no chunks with these prior_token_ids' do
      prior_token_ids = [5, 6, 7]

      expect(Chunk.by_starting_token_ids(prior_token_ids).count).to eq(0)
    end

    it 'returns chunks with these prior_token_ids' do
      expect(Chunk.by_starting_token_ids(prior_token_ids).first).to eq(chunk)
    end

    it 'handles long prior_token_ids' do
      prior_token_ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      expect(Chunk.by_starting_token_ids(prior_token_ids).count).to eq(0)
    end
  end

  describe "#by_current_word" do
    
  end
end
