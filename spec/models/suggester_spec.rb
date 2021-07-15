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

    context 'when text is not empty' do # rubocop:disable Metrics/BlockLength
      let(:suggester) { Suggester.new(params) }

      before(:each) do
        allow(suggester)
          .to receive(:get_candidate_chunks)
          .and_return('some candidates')
      end

      it 'finds latest word being typed' do
        expect(suggester).to receive(:find_current_word)

        suggester.suggest
      end

      it 'finds prior tokens' do
        expect(suggester).to receive(:find_prior_token_ids)

        suggester.suggest
      end

      it 'gets chunk candidates' do
        expect(suggester).to receive(:get_candidate_chunks)

        suggester.suggest
      end

      it 'builds suggestions' do
        expect(suggester).to receive(:build_suggestions)

        suggester.suggest
      end

      it 'returns suggestions' do
        allow(suggester).to receive(:build_suggestions).and_return('suggestions')

        suggestions = suggester.suggest

        expect(suggestions).to eq('suggestions')
      end
    end
  end

  # it 'gets possible tokens based on the current word' do
  #   allow(suggester).to receive(:find_current_word).and_return('current_word')
  #   expect(suggester).to receive(:get_possible_token_ids).with('current_word')

  #   suggester.suggest
  # end

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

  describe '.get_possible_token_ids' do # rubocop:disable Metrics/BlockLength
    let!(:mope_token_id) { Token.id_ise('mope', :by_word).first }
    let!(:moon_token_id) { Token.id_ise('moon', :by_word).first }
    let!(:mike_token_id) { Token.id_ise('mike', :by_word).first }

    it 'returns [] when no matches' do
      suggester = Suggester.new(params)

      # a word that we have never seen before
      current_word = 'zigsbery'

      expect(suggester.get_possible_token_ids(current_word)).to eq([])
    end

    it 'returns [] with empty word' do
      suggester = Suggester.new(params)

      # a word that we have never seen before
      current_word = ''

      expect(suggester.get_possible_token_ids(current_word)).to eq([])
    end

    context 'some sample tokens in database' do
      it 'works for 1 character words' do
        current_word = 'm'
        params[:text] = current_word
        suggester = Suggester.new(params)

        possible_token_ids = suggester.get_possible_token_ids(current_word)

        expect(possible_token_ids).to include(mope_token_id)
        expect(possible_token_ids).to include(moon_token_id)
        expect(possible_token_ids).to include(mike_token_id)
      end

      it 'works for 2 character words' do
        current_word = 'mo'
        params[:text] = current_word
        suggester = Suggester.new(params)

        possible_token_ids = suggester.get_possible_token_ids(current_word)

        expect(possible_token_ids).to include(mope_token_id)
        expect(possible_token_ids).to include(moon_token_id)
        expect(possible_token_ids).to_not include(mike_token_id)
      end
    end
  end

  describe '.find_prior_token_ids' do # rubocop:disable Metrics/BlockLength
    let(:max_tokens_to_return) { ChunkAnalyser::CHUNK_SIZE_RANGE.max - 1 }

    before(:each) do
      # add some tokens to the database
      Token.create!({ id: 1, text: 'the' })
      Token.create!({ id: 2, text: ' ' })
      Token.create!({ id: 3, text: 'cat' })
      Token.create!({ id: 4, text: 'in' })
      Token.create!({ id: 5, text: 'hat' })
    end

    it 'returns the prior tokens' do
      texts_and_expectations = [
        { text: 'the', expected_token_ids: nil },
        { text: 'the   ', expected_token_ids: [1] }, # spaces at the end]
        { text: 'the ca', expected_token_ids: [1, 2] },
        { text: 'the cat', expected_token_ids: [1, 2] },
        { text: 'the cat ', expected_token_ids: [1, 2, 3] }
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

    it 'returns a maximum of the last 7 tokens' do
      text = 'the cat in the hat in' # 11 tokens (6 words, 5 spaces)
      params[:text] = text
      suggester = Suggester.new(params)
      prior_token_ids = suggester.find_prior_token_ids
      expect(prior_token_ids.length)
        .to eq(max_tokens_to_return)
      expect(prior_token_ids)
        .to eq([2, 4, 2, 1, 2, 5, 2]) # ' in the hat '
    end

    it 'returns exactly 7 tokens if 7 plus a word submitted' do
      text = 'the cat in the hat' # 8 tokens plus the final word "hat"
      params[:text] = text
      suggester = Suggester.new(params)
      prior_token_ids = suggester.find_prior_token_ids
      expect(prior_token_ids.length)
        .to eq(max_tokens_to_return)
      expect(prior_token_ids)
        .to eq([2, 3, 2, 4, 2, 1, 2]) # ' cat in the '
    end
  end

  describe '.get_candidate_chunks' do # rubocop:disable Metrics/BlockLength
    context 'we have prior tokens and a current word' do # rubocop:disable Metrics/BlockLength
      let(:prior_token_ids) { [1, 2, 3, 4] }
      let(:current_word) { 'ha' }
      let(:candidate_token_ids) { [] }
      let(:suggester) { Suggester.new(params) }
      let(:max_suggestions) { Suggester::MAX_SUGGESTIONS }

      context '5 or more candidates for initial prior tokens' do # rubocop:disable Metrics/BlockLength
        let(:five_chunk_candidates_by_prior_tokens) do
          double(
            'AR Relation 5 candidates',
            count: max_suggestions,
            to_a: Array.new(max_suggestions)
          )
            .as_null_object
        end

        before(:each) do
          allow(suggester)
            .to receive(:get_chunks_by_prior_tokens)
            .and_return(five_chunk_candidates_by_prior_tokens)

          allow(suggester)
            .to receive(:get_token_candidates_from_chunks)
            .and_return(Array.new(five_chunk_candidates_by_prior_tokens.count, 'some token'))
        end

        it 'gets chunks by prior tokens' do
          expect(suggester)
            .to receive(:get_chunks_by_prior_tokens)
            .with(prior_token_ids, current_word, candidate_token_ids)

          suggester.get_candidate_chunks(prior_token_ids, current_word)
        end

        it 'gets the token candidates from those chunks' do
          expect(suggester)
            .to receive(:get_token_candidates_from_chunks)

          suggester.get_candidate_chunks(prior_token_ids, current_word)
        end

        it 'returns those chunks' do
          candidate_chunks = suggester.get_candidate_chunks(prior_token_ids, current_word)

          expect(candidate_chunks)
            .to eq(five_chunk_candidates_by_prior_tokens)
        end

        it 'should not call get_candidate_chunks again' do
          expect(suggester)
            .to receive(:get_candidate_chunks)
            .at_most(:once)

          suggester.get_candidate_chunks(prior_token_ids, current_word)
        end
      end

      context 'less than 5 candidates for initial prior tokens' do # rubocop:disable Metrics/BlockLength
        let(:three_candidate_token_ids) { Array.new(3, 'some token') }
        let(:two_candidate_token_ids) { Array.new(2, 'some token') }

        let(:three_chunk_candidates_by_prior_tokens) { Array.new(3, 'some chunks') }
        let(:two_chunk_candidates_by_prior_tokens) { Array.new(2, 'some other chunks') }

        let(:five_chunk_candidates_by_prior_tokens) do
          three_chunk_candidates_by_prior_tokens + two_chunk_candidates_by_prior_tokens
        end

        before(:each) do
          allow(suggester)
            .to receive(:get_chunks_by_prior_tokens)
            .with(prior_token_ids, current_word, [])
            .and_return(three_chunk_candidates_by_prior_tokens)

          allow(suggester)
            .to receive(:get_chunks_by_prior_tokens)
            .with(prior_token_ids[1..], current_word, three_candidate_token_ids)
            .and_return(two_chunk_candidates_by_prior_tokens)

          allow(suggester)
            .to receive(:get_token_candidates_from_chunks)
            .with(three_chunk_candidates_by_prior_tokens.to_a)
            .and_return(three_candidate_token_ids)

          allow(suggester)
            .to receive(:get_token_candidates_from_chunks)
            .with(two_chunk_candidates_by_prior_tokens.to_a)
            .and_return(two_candidate_token_ids)
        end

        it 'gets chunks by prior tokens twice' do
          expect(suggester)
            .to receive(:get_chunks_by_prior_tokens)
            .twice

          suggester.get_candidate_chunks(prior_token_ids, current_word)
        end

        it 'gets chunks by less prior tokens' do
          expect(suggester)
            .to receive(:get_chunks_by_prior_tokens)
            .with(prior_token_ids, current_word, [])
            .once

          expect(suggester)
            .to receive(:get_chunks_by_prior_tokens)
            .with(prior_token_ids[1..], current_word, three_candidate_token_ids)
            .once

          suggester.get_candidate_chunks(prior_token_ids, current_word)
        end

        it 'returns all those chunks' do
          result = suggester.get_candidate_chunks(prior_token_ids, current_word)

          expect(result).to eq(five_chunk_candidates_by_prior_tokens)
        end
      end
    end
  end

  describe '.get_chunks_by_prior_tokens' do # rubocop:disable Metrics/BlockLength
    let(:prior_token_ids) { [1, 2, 3, 4] }
    let(:current_word) { 'ha' }
    let(:candidate_token_ids) { [] }
    let(:suggester) { Suggester.new(params) }
    let(:max_suggestions) { Suggester::MAX_SUGGESTIONS }

    context '5 or more candidates for prior tokens and the current word' do # rubocop:disable Metrics/BlockLength
      let(:chunk_candidates_by_prior_tokens_and_current_word) do
        double('AR Relation 7 candidates', count: max_suggestions + 2)
          .as_null_object
      end

      let(:five_chunk_candidates_by_prior_tokens_and_current_word) do
        double('AR Relation 5 candidates', count: max_suggestions)
          .as_null_object
      end

      before(:each) do
        allow(suggester)
          .to receive(:get_chunks_by_prior_tokens_and_current_word)
          .and_return(chunk_candidates_by_prior_tokens_and_current_word)

        allow(chunk_candidates_by_prior_tokens_and_current_word)
          .to receive(:limit)
          .and_return(five_chunk_candidates_by_prior_tokens_and_current_word)

        allow(five_chunk_candidates_by_prior_tokens_and_current_word)
          .to receive(:to_a)
          .and_return(Array.new(five_chunk_candidates_by_prior_tokens_and_current_word.count, 'some chunk'))

        allow(suggester)
          .to receive(:get_token_candidates_from_chunks)
          .and_return(Array.new(five_chunk_candidates_by_prior_tokens_and_current_word.count, 'some token'))
      end

      it 'gets chunks by prior tokens and current word' do
        expect(suggester)
          .to receive(:get_chunks_by_prior_tokens_and_current_word)
          .with(prior_token_ids, current_word, candidate_token_ids)

        suggester.get_chunks_by_prior_tokens(prior_token_ids, current_word, candidate_token_ids)
      end

      it 'doesn\'t get chunks just by prior tokens' do
        expect(suggester)
          .not_to receive(:get_chunks_by_prior_tokens_only)
          .with(prior_token_ids, candidate_token_ids)

        suggester.get_chunks_by_prior_tokens(prior_token_ids, current_word, candidate_token_ids)
      end

      it 'returns chunk_candidates' do
        # expect(suggester)
        #   .to receive(:get_chunks_by_prior_tokens_and_current_word)
        #   .and_return(chunk_candidates_by_prior_tokens_and_current_word)

        expect(suggester.get_chunks_by_prior_tokens(prior_token_ids, current_word, candidate_token_ids))
          .to eq(five_chunk_candidates_by_prior_tokens_and_current_word.to_a)
      end
    end

    context 'less than 5 candidates for prior tokens and the current word, but 5 or more for the prior tokens only' do # rubocop:disable Metrics/BlockLength
      let(:three_candidate_token_ids) { Array.new(3, 'some token') }
      let(:two_candidate_token_ids) { Array.new(2, 'some token') }

      let(:three_chunk_candidates_by_prior_tokens_and_current_word) do
        double('AR first candidates', count: max_suggestions - 2, to_a: Array.new(3, 'some chunks'))
          .as_null_object
      end

      let(:seven_chunk_candidates_by_prior_tokens) do
        double('AR next 7 candidates', count: max_suggestions + 2)
          .as_null_object
      end

      let(:four_chunk_candidates_by_prior_tokens) do
        double('AR next 4 candidates', count: 4).as_null_object
      end

      let(:two_chunk_candidates_by_prior_tokens) do
        double('AR next 2 candidates', count: 2, to_a: Array.new(2, 'some other chunks')).as_null_object
      end

      before(:each) do
        allow(suggester)
          .to receive(:get_chunks_by_prior_tokens_and_current_word)
          .and_return(three_chunk_candidates_by_prior_tokens_and_current_word)

        allow(three_chunk_candidates_by_prior_tokens_and_current_word)
          .to receive(:limit)
          .and_return(three_chunk_candidates_by_prior_tokens_and_current_word)

        allow(suggester)
          .to receive(:get_token_candidates_from_chunks)
          .with(three_chunk_candidates_by_prior_tokens_and_current_word.to_a)
          .and_return(three_candidate_token_ids)

        allow(suggester)
          .to receive(:get_chunks_by_prior_tokens_only)
          .and_return(seven_chunk_candidates_by_prior_tokens)

        allow(seven_chunk_candidates_by_prior_tokens)
          .to receive(:limit)
          .and_return(two_chunk_candidates_by_prior_tokens)

        allow(suggester)
          .to receive(:get_token_candidates_from_chunks)
          .with(two_chunk_candidates_by_prior_tokens.to_a)
          .and_return(two_candidate_token_ids)
      end

      it 'gets chunks by prior tokens and current word' do
        expect(suggester)
          .to receive(:get_chunks_by_prior_tokens_and_current_word)
          .with(prior_token_ids, current_word, candidate_token_ids)

        suggester.get_chunks_by_prior_tokens(prior_token_ids, current_word, candidate_token_ids)
      end

      it 'also gets chunks just by prior tokens without previously found chunks' do
        candidate_token_ids = ['some token', 'some token', 'some token']

        expect(suggester)
          .to receive(:get_chunks_by_prior_tokens_only)
          .with(prior_token_ids, candidate_token_ids)

        suggester.get_chunks_by_prior_tokens(prior_token_ids, current_word, [])
      end

      it 'returns chunk_candidates' do
        result = suggester.get_chunks_by_prior_tokens(prior_token_ids, current_word)

        expect(result)
          .to eq(
            three_chunk_candidates_by_prior_tokens_and_current_word.to_a + two_chunk_candidates_by_prior_tokens.to_a
          )
      end
    end
  end

  describe '.get_chunks_by_prior_tokens_and_current_word' do # rubocop:disable Metrics/BlockLength
    let!(:token_the) { create(:token, id: 1, text: 'the') }
    let!(:token_space) { create(:token, id: 2, text: ' ') }

    let!(:token_hat) { create(:token, id: 10, text: 'hat') }
    let!(:token_ham) { create(:token, id: 11, text: 'ham') }
    let!(:token_has) { create(:token, id: 12, text: 'has') }
    let!(:token_hit) { create(:token, id: 13, text: 'hit') }
    let!(:token_ha) { create(:token, id: 14, text: 'ha') }

    let!(:chunk1) { create(:chunk, language: language, token_ids: [1, 2, 10]) }
    let!(:chunk2) { create(:chunk, language: language, token_ids: [1, 2, 11]) }
    let!(:chunk3) { create(:chunk, language: language, token_ids: [1, 2, 12]) }
    let!(:chunk4) { create(:chunk, language: language, token_ids: [1, 2, 13]) }

    let(:suggester) { Suggester.new(params) }

    it 'looks for token candidates for the current word' do
      current_word = 'ha'
      expect(Token).to receive(:get_candidate_tokens).with(current_word)

      suggester.get_chunks_by_prior_tokens_and_current_word([1, 2, 10], current_word)
    end

    context 'when no candidate token ids' do
      let(:candidate_token_ids) { [] }
      let(:candidate_tokens_for_current_word) { double('Some tokens', to_a: [token_hat, token_ham, token_has]) }

      before(:each) do
        allow(Token).to receive(:get_candidate_tokens).and_return(candidate_tokens_for_current_word)
      end

      it 'returns chunks if there are some' do
        prior_token_ids = [1, 2]
        current_word = 'ha'
        chunks = suggester
                 .get_chunks_by_prior_tokens_and_current_word(
                   prior_token_ids, current_word, candidate_token_ids
                 )

        expect(chunks.length).to eq(3)
      end

      context 'doesn\'t return chunks if there are none' do
        it 'because there are no matching prior_token_ids'
        it 'because there are no matching tokens for the current_word'
      end
    end

    context 'when there are candidate token ids' do
      it 'returns chunks'
    end
  end

  describe '.get_chunks_by_prior_tokens_only' do
  end

  describe '.get_suggestions' do
    it 'creates a where clause for the prior tokens'
    it 'creates a where clause for the possible tokens'
    it 'retrieves some chunks from the database'
    context 'no prior tokens' do
    end

    context 'no possible tokens' do
    end
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
