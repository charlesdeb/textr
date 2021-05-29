# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Suggester, type: :model do # rubocop:disable Metrics/BlockLength
  let(:language) { create(:language, language: 'Klingon') }
  let(:params) do
    { text: 'the ca', language_id: language.id.to_s, show_analysis: 'false' }
  end
  describe '#initialize' do
    it 'sets instance variables' do
      suggester = Suggester.new(params)
      expect(suggester.instance_variable_get(:@text)).to eq(params[:text])
      expect(suggester.instance_variable_get(:@language_id)).to eq(params[:language_id].to_i)
      expect(suggester.instance_variable_get(:@show_analysis)).to eq(false)
    end
  end

  describe '.suggest' do # rubocop:disable Metrics/BlockLength
    context 'when text is empty' do
      it 'returns no candidates' do
        params[:text] = ''
        output = Suggester.new(params).suggest

        expect(output[:candidates]).to eq([])
        expect(output[:analysis]).to be_nil
      end

      it 'handles text full of spaces' do
        params[:text] = '   '
        output = Suggester.new(params).suggest

        expect(output[:candidates]).to eq([])
        expect(output[:analysis]).to be_nil
      end

      it 'gives a reason when analysis is required' do
        params[:text] = ''
        params[:show_analysis] = 'true'
        output = Suggester.new(params).suggest

        expect(output[:analysis]).to eq('No text provided')
      end

      it 'gives no analysis if not required' do
        params[:text] = ''
        output = Suggester.new(params).suggest

        expect(output).to_not include(:analysis)
      end
    end

    context 'when text is not empty' do
      let(:suggester) { Suggester.new(params) }

      it 'finds latest word being typed' do
        expect(suggester).to receive(:find_current_word)

        suggester.suggest
      end

      it 'gets possible tokens based on the current word' do
        allow(suggester).to receive(:find_current_word).and_return('current_word')
        expect(suggester).to receive(:get_possible_token_ids).with('current_word')

        suggester.suggest
      end

      it 'finds prior tokens' do
        expect(suggester).to receive(:find_prior_token_ids)

        suggester.suggest
      end

      it 'gets suggestions' do
        allow(suggester).to receive(:get_suggestions).and_return('sugestions')

        expect(suggester.suggest).to eq('sugestions')
      end

      it 'returns suggestions' do
        expect(suggester).to receive(:get_suggestions)

        suggester.suggest
      end
    end
  end

  describe '.find_current_word' do
    it 'handles spaces at the end' do
      texts = [' ', '  ', 'cat ', 'cat  ']
      texts.each do |text|
        params[:text] = text
        suggester = Suggester.new(params)
        current_word = suggester.find_current_word
        expect(current_word).to eq(' '), "expected ' ', got '#{current_word}' from input of '#{text}'"
      end
    end

    it 'returns the current word' do
      expected_word = 'cat'
      texts = [expected_word, "the #{expected_word}", "the  #{expected_word}"]
      texts.each do |text|
        params[:text] = text
        suggester = Suggester.new(params)
        current_word = suggester.find_current_word
        expect(current_word)
          .to eq(expected_word),
              "expected '#{expected_word}', got '#{current_word}' from input of '#{text}'"
      end
    end
  end

  describe '.get_possible_token_ids' do
  end

  describe '.find_prior_token_ids' do # rubocop:disable Metrics/BlockLength
    before(:each) do
      # add some tokens to the database
      Token.create!({ id: 1, text: 'the' })
      Token.create!({ id: 2, text: ' ' })
      Token.create!({ id: 3, text: 'cat' })
      Token.create!({ id: 4, text: 'in' })
      Token.create!({ id: 5, text: 'hat' })
    end

    it 'handles spaces at the end'

    it 'returns the prior tokens' do
      texts_and_expectations = [
        { text: 'the', expected_token_ids: nil },
        { text: 'the ', expected_token_ids: [1] },
        { text: 'the ca', expected_token_ids: [1, 2] },
        { text: 'the cat', expected_token_ids: [1, 2] },
        { text: 'the cat ', expected_token_ids: [1, 2, 3] },
        { text: 'the cat in the hat', expected_token_ids: [1, 2, 3, 2, 4, 2, 1, 2] }
      ]
      texts_and_expectations.each do |text_and_expectation|
        params[:text] = text_and_expectation[:text]
        expected_token_ids = text_and_expectation[:expected_token_ids]
        suggester = Suggester.new(params)
        prior_token_ids = suggester.find_prior_token_ids
        expect(prior_token_ids)
          .to eq(expected_token_ids),
              "expected '#{expected_token_ids}', got '#{prior_token_ids}' from input of '#{params[:text]}'"
      end
    end
  end

  describe '.get_suggestions' do
  end

  describe '.suggestions_by_current_word' do # rubocop:disable Metrics/BlockLength
    let(:current_word) { 'ca' }
    let(:token_ids) { [1, 2] }
    let(:params) do
      { text: current_word, language_id: language.id.to_s, show_analysis: 'false' }
    end
    let(:suggester) { Suggester.new(params) }

    it 'converts the current word to single character tokens' do
      expect(Token).to receive(:id_ise).with(current_word, :by_letter).and_return([1, 2])

      suggester.suggestions_by_current_word(current_word)
    end

    it 'gets candidates by starting tokens' do
      allow(Token).to receive(:id_ise).with(current_word, :by_letter).and_return(token_ids)

      expect(Chunk).to receive(:by_starting_tokens).with(token_ids, language.id)

      suggester.suggestions_by_current_word(current_word)
    end

    it 'output hash contains candidates key' do
      suggestions = suggester.suggestions_by_current_word(current_word)

      expect(suggestions).to include(:candidates)
    end

    it 'output hash does not contain analysis key if not required' do
      suggestions = suggester.suggestions_by_current_word(current_word)

      expect(suggestions).to_not include(:analysis)
    end

    it 'output hash contains analysis key if required' do
      params = {  text: current_word, language_id: language.id.to_s, show_analysis: 'true' }
      suggester = Suggester.new(params)

      suggestions = suggester.suggestions_by_current_word(current_word)

      expect(suggestions).to include(:analysis)
    end
  end

  skip '.suggestions_by_current_word_and_prior_token_ids' do
    it 'hash contains candidates' do
      output = Suggester.new(params).suggest
      expect(output).to include(:candidates)
    end

    it 'hash contains analysis if requested' do
      params[:show_analysis] = 'true'
      output = Suggester.new(params).suggest
      expect(output).to include(:analysis)
    end

    it 'hash does not contains analysis if not requested' do
      output = Suggester.new(params).suggest
      expect(output).to_not include(:analysis)
    end
  end
end
