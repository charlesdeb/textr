# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Suggester, type: :model do # rubocop:disable Metrics/BlockLength
  let(:language) { create(:language, language: 'Klingon') }
  let(:params) do
    { text_message: 'the ca', language_id: language.id.to_s, show_analysis: 'false' }
  end
  describe '#initialize' do
    it 'sets instance variables' do
      suggester = Suggester.new(params)
      expect(suggester.instance_variable_get(:@text_message)).to eq(params[:text_message])
      expect(suggester.instance_variable_get(:@language_id)).to eq(params[:language_id])
      expect(suggester.instance_variable_get(:@show_analysis)).to eq(false)
    end
  end

  describe '.suggest' do # rubocop:disable Metrics/BlockLength
    context 'when text_message is empty' do
      it 'returns no candidates or analysis' do
        params[:text_message] = ''
        output = Suggester.new(params).suggest

        expect(output[:candidates]).to eq([])
        expect(output[:analysis]).to be_nil
      end
    end

    context 'when text_message is not empty' do # rubocop:disable Metrics/BlockLength
      let(:suggester) { Suggester.new(params) }

      it 'finds latest word being typed' do
        expect(suggester).to receive(:find_current_word)

        suggester.suggest
      end

      it 'finds prior tokens' do
        expect(suggester).to receive(:find_prior_tokens)

        suggester.suggest
      end

      context 'when no prior words/tokens' do
        it 'suggests a word based on what is being typed' do
          params[:text_message] = 'th'
          current_word = params[:text_message]
          suggester = Suggester.new(params)
          allow(suggester).to receive(:find_current_word).and_return(current_word)
          allow(suggester).to receive(:find_prior_tokens).and_return(nil)

          expect(suggester).to receive(:candidates_by_current_word).with(current_word)

          suggester.suggest
        end
      end

      context 'when there are prior words/tokens' do
        it 'suggests a word based on what is being typed and what came before' do
          params[:text_message] = 'the ca'
          prior_tokens = [1]
          current_word = params[:text_message].split[-1]
          suggester = Suggester.new(params)
          allow(suggester).to receive(:find_current_word).and_return(current_word)
          allow(suggester).to receive(:find_prior_tokens).and_return(prior_tokens)

          expect(suggester).to receive(:candidates_by_current_word_and_tokens).with(current_word, prior_tokens)

          suggester.suggest
        end
      end
    end
  end

  describe '.find_current_word' do
    it 'returns a space if the user just typed a space'
    it 'returns a space if the user just typed a space'
  end

  describe '.find_prior_tokens' do
  end

  skip '.candidates_by_current_word' do
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

  skip '.candidates_by_current_word_and_tokens' do
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
