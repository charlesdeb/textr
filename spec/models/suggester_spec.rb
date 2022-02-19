# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Suggester, type: :model do # rubocop:disable Metrics/BlockLength
  let(:language) { create(:language, language: 'Klingon') }
  let(:params) do
    { text: 'the ca', language_id: language.id.to_s, show_analysis: 'false' }
  end

  subject(:suggester) {Suggester.new(params)}

  describe '#initialize' do
    it 'sets instance variables' do
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
        # expect(output[:analysis]).to be_nil
      end

      it 'handles text full of spaces' do
        params[:text] = '   '
        output = Suggester.new(params).suggest

        expect(output[:candidates]).to eq([])
        expect(output[:analysis]).to be_nil
      end

      it 'gives a reason when analysis is required', skip: 'Not showing analysis for now' do
        params[:text] = ''
        params[:show_analysis] = 'true'
        output = Suggester.new(params).suggest

        expect(output[:analysis]).to eq('No input text provided')
      end

      it 'gives no analysis if not required', skip: 'Not showing analysis for now' do
        params[:text] = ''
        output = Suggester.new(params).suggest

        expect(output).to_not include(:analysis)
      end
    end

    context 'when text is not empty' do

      before(:each) do
        allow(suggester)
          .to receive(:get_candidate_chunks)
          .and_return('some candidates')
        allow(suggester)
          .to receive(:build_suggestions)
      end

      it 'finds prior tokens' do
        expect(suggester).to receive(:prior_token_ids)

        suggester.suggest
      end

      it 'gets chunk candidates' do
        expect(suggester).to receive(:get_candidate_chunks)

        suggester.suggest
      end

      it 'returns suggestions' do
        allow(suggester).to receive(:build_suggestions).and_return('suggestions')

        suggestions = suggester.suggest

        expect(suggestions).to eq('suggestions')
      end
    end
  end

  describe '.current_word' do
    it 'handles spaces at the end' do
      texts = [' ', '  ', 'cat ', 'cat  ']
      texts.each do |text|
        params[:text] = text
        suggester = Suggester.new(params)
        current_word = suggester.current_word
        # expect(current_word).to eq(' '), "expected ' ', got '#{current_word}' from input of '#{text}'"
        expect(current_word).to eq(nil), "expected nil, got '#{current_word}' from input of '#{text}'"
      end
    end

    it 'returns the current word' do
      expected_word = 'cat'
      texts = [expected_word, "the #{expected_word}", "the  #{expected_word}"]
      texts.each do |text|
        params[:text] = text
        suggester = Suggester.new(params)
        current_word = suggester.current_word
        expect(current_word)
          .to eq(expected_word),
              "expected '#{expected_word}', got '#{current_word}' from input of '#{text}'"
      end
    end
  end

  describe '.prior_token_ids' do # rubocop:disable Metrics/BlockLength
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
        { text: 'the', expected_token_ids: [] },
        { text: 'the   ', expected_token_ids: [1, 2] }, # spaces at the end
        { text: 'the ca', expected_token_ids: [1, 2] },
        { text: 'the cat', expected_token_ids: [1, 2] },
        { text: 'the cat ', expected_token_ids: [1, 2, 3, 2] }
      ]
      texts_and_expectations.each do |text_and_expectation|
        params[:text] = text_and_expectation[:text]
        expected_token_ids = text_and_expectation[:expected_token_ids]
        suggester = Suggester.new(params)
        prior_token_ids = suggester.prior_token_ids
        expect(prior_token_ids)
          .to eq(expected_token_ids),
              "expected '#{expected_token_ids}', got '#{prior_token_ids}' from input of '#{params[:text]}'"
      end
    end

    it 'returns a maximum of the last 7 tokens' do
      text = 'the cat in the hat in' # 11 tokens (6 words, 5 spaces)
      params[:text] = text
      suggester = Suggester.new(params)
      prior_token_ids = suggester.prior_token_ids
      expect(prior_token_ids.length)
        .to eq(max_tokens_to_return)
      expect(prior_token_ids)
        .to eq([2, 4, 2, 1, 2, 5, 2]) # ' in the hat '
    end

    it 'returns exactly 7 tokens if 7 plus a word submitted' do
      text = 'the cat in the hat' # 8 tokens plus the final word "hat"
      params[:text] = text
      suggester = Suggester.new(params)
      prior_token_ids = suggester.prior_token_ids
      expect(prior_token_ids.length)
        .to eq(max_tokens_to_return)
      expect(prior_token_ids)
        .to eq([2, 3, 2, 4, 2, 1, 2]) # ' cat in the '
    end

    it 'returns exactly 2 tokens if 1 plus a word submitted' do
      text = 'the c' # 8 tokens plus the final word "hat"
      params[:text] = text
      suggester = Suggester.new(params)
      prior_token_ids = suggester.prior_token_ids
      expect(prior_token_ids.length)
        .to eq(2)
      expect(prior_token_ids)
        .to eq([1, 2]) # 'the '
    end

    it 'doesn\'t add the current word to the table of tokens' do
      params[:text] = 'the rain'
      suggester = Suggester.new(params)
      suggester.prior_token_ids

      expect(Token.all.count).to eq(5)

      token_texts = Token.all.map(&:text)
      expect(token_texts).to_not include('rain')
    end

    it 'returns empty array if there are no prior token ids' do
      params[:text] = 'the'
      suggester = Suggester.new(params)
      result = suggester.prior_token_ids

      expect(result).to be_empty
    end
  end

  describe '.get_candidate_chunks' do # rubocop:disable Metrics/BlockLength
    let(:prior_token_ids) { [1, 2, 3, 4] }
    let(:current_word) { 'ca' }
    let(:candidate_token_ids) { [] }
    let(:max_suggestions) { Suggester::MAX_SUGGESTIONS }

    let(:five_chunk_candidates) do
      double(
        'AR Relation 5 candidates',
        count: max_suggestions,
        to_a: Array.new(max_suggestions)
      )
        .as_null_object
    end

    let(:four_chunk_candidates) do
      double(
        'AR Relation 4 candidates',
        count: max_suggestions - 1,
        to_a: Array.new(max_suggestions - 1)
      )
        .as_null_object
    end

    it 'finds latest word being typed' do
      expect(suggester).to receive(:current_word)

      suggester.suggest
    end

    context '5 candidates for the prior tokens and the current word' do
      before(:each) do
        allow(suggester)
          .to receive(:get_chunks_by_prior_tokens_and_current_word)
          .and_return(five_chunk_candidates)

        allow(suggester)
          .to receive(:get_token_id_candidates_from_chunks)
          .and_return(Array.new(five_chunk_candidates.count, 'some token'))
      end

      it 'gets chunks by prior tokens and current word' do
        expect(suggester)
          .to receive(:get_chunks_by_prior_tokens_and_current_word)
          .with(prior_token_ids, candidate_token_ids)
          .once

        suggester.get_candidate_chunks(prior_token_ids)
      end

      it "doesn't get chunks by prior tokens only" do
        expect(suggester)
          .not_to receive(:get_chunks_by_prior_tokens_only)
          .with(prior_token_ids, candidate_token_ids)

        suggester.get_candidate_chunks(prior_token_ids)
      end
    end

    context 'less than 5 candidates for the prior tokens and the current word' do
      before(:each) do
        allow(suggester)
          .to receive(:get_chunks_by_prior_tokens_and_current_word)
          .and_return(four_chunk_candidates)

        allow(suggester)
          .to receive(:get_token_id_candidates_from_chunks)
          .and_return(Array.new(four_chunk_candidates.count, 'some token'))

        allow(suggester)
          .to receive(:get_chunks_by_prior_tokens_only)
        # .and_return(Array.new(four_chunk_candidates.count, 'some token'))
      end

      it 'gets chunks by prior tokens and current word' do
        expect(suggester)
          .to receive(:get_chunks_by_prior_tokens_and_current_word)
          .with(prior_token_ids, candidate_token_ids)

        suggester.get_candidate_chunks(prior_token_ids)
      end

      it 'also gets chunks by prior tokens only' do
        expect(suggester)
          .to receive(:get_chunks_by_prior_tokens_only)
          .with(prior_token_ids, Array.new(four_chunk_candidates.count, 'some token'))

        suggester.get_candidate_chunks(prior_token_ids)
      end
    end
  end

  context 'chunk methods that need chunks from the database' do # rubocop:disable Metrics/BlockLength
    let!(:token_the) { create(:token, id: 1, text: 'the') }
    let!(:token_space) { create(:token, id: 2, text: ' ') }
    let!(:token_my) { create(:token, id: 3, text: 'my') }

    let!(:token_hat) { create(:token, id: 10, text: 'hat') }
    let!(:token_ham) { create(:token, id: 11, text: 'ham') }
    let!(:token_has) { create(:token, id: 12, text: 'has') }
    let!(:token_hit) { create(:token, id: 13, text: 'hit') }
    let!(:token_ha) { create(:token, id: 14, text: 'ha') }
    let!(:token_heap) { create(:token, id: 15, text: 'heap') }
    let!(:token_heart) { create(:token, id: 16, text: 'heart') }
    let!(:token_moon) { create(:token, id: 17, text: 'moon') }
    let!(:token_hearts) { create(:token, id: 18, text: 'hearts') }

    let!(:chunk_ending_in_hat) do
      # the hat
      create(:chunk, language: language, count: 5, token_ids: [1, 2, 10], size: 3)
    end
    let!(:chunk_the_ham) do
      # the ham
      create(:chunk, language: language, count: 10, token_ids: [1, 2, 11], size: 3)
    end
    let!(:chunk_the_has) do
      # the has
      create(:chunk, language: language, count: 15, token_ids: [1, 2, 12], size: 3)
    end
    let!(:chunk4) do
      # the hit
      create(:chunk, language: language, count: 1, token_ids: [1, 2, 13], size: 3)
    end
    let!(:chunk5) do
      # thethehit
      create(:chunk, language: language, count: 1, token_ids: [1, 1, 13], size: 3)
    end

    let!(:chunk_my_hat) do
      # my hat
      create(:chunk, language: language, count: 1, token_ids: [3, 2, 10], size: 3)
    end

    let!(:chunk_the_heap) do
      # the heap
      create(:chunk, language: language, count: 1, token_ids: [1, 2, 15], size: 3)
    end

    let!(:chunk_my_heart) do
      # my heart
      create(:chunk, language: language, count: 5, token_ids: [3, 2, 16], size: 3)
    end

    let!(:chunk__heart) do
      # _heart
      create(:chunk, language: language, count: 1, token_ids: [2, 16], size: 2)
    end

    let!(:chunk__hearts) do
      # _hearts
      create(:chunk, language: language, count: 3, token_ids: [2, 18], size: 2)
    end

    let!(:chunk_the_moon) do
      # the_moon
      create(:chunk, language: language, count: 5, token_ids: [1, 2, 17], size: 3)
    end

    describe '.get_chunks_by_prior_tokens_and_current_word' do # rubocop:disable Metrics/BlockLength
      let(:prior_token_ids) { [1, 2] }
      let(:current_word) { 'ha' }
      let(:candidate_token_ids) { [] }

      before(:each) do
        allow(suggester)
          .to receive(:current_word)
          .and_return(current_word)
      end

      it 'looks for token candidates for the current word' do
        allow(Token).to receive(:starting_with).with(current_word).and_return(Token.none)

        suggester.get_chunks_by_prior_tokens_and_current_word([1, 2])
      end

      it 'orders the candidates correctly' do
        chunks = suggester
                 .get_chunks_by_prior_tokens_and_current_word(
                   prior_token_ids, candidate_token_ids
                 )

        expect(chunks.first.count).to be > chunks.last.count
      end

      context 'when 5 candidates for the prior tokens and the current word' do
        let(:current_word) { 'h' }
        it 'looks in the database for chunks only once' do
          expect(Chunk).to receive(:where).at_most(:once).and_call_original
          suggester.get_chunks_by_prior_tokens_and_current_word([1, 2])
        end

        it 'returns the candidates' do
          result = suggester.get_chunks_by_prior_tokens_and_current_word([1, 2])

          expect(result.length).to eq(5)
        end
      end

      context 'when less than 5 candidates for the prior tokens and the current word' do
        it 'gets chunks by prior tokens and current word recursively' do
          allow(suggester)
            .to receive(:current_word)
            .and_return('ha')
          expect(suggester).to receive(:get_chunks_by_prior_tokens_and_current_word).at_least(:twice).and_call_original

          suggester.get_chunks_by_prior_tokens_and_current_word([1, 2])
        end

        it 'adds new chunks to the old as it recurses' do
          # first time through, it will match 'the heap'.
          # second time through, it will match ' heart' and ' hearts'
          allow(suggester)
            .to receive(:current_word)
            .and_return('he')
          chunks = suggester.get_chunks_by_prior_tokens_and_current_word([1, 2])

          expect(chunks.length).to eq(3)
        end

        it 'orders the new chunks after the old' do
          allow(suggester)
            .to receive(:current_word)
            .and_return('he')

          chunks = suggester.get_chunks_by_prior_tokens_and_current_word([1, 2])

          expect(chunks[0]).to eq(chunk_the_heap)   # count 1 (but more prior tokens)
          expect(chunks[1]).to eq(chunk__hearts)    # count 3
          expect(chunks[2]).to eq(chunk__heart)     # count 1
        end
      end

      context 'when no chunk candidates for the current word' do
        let(:current_word) { 'zoo' }
        it 'doesn\'t look in the database for chunks' do
          expect(Chunk).not_to receive(:where).and_call_original

          chunks = suggester.get_chunks_by_prior_tokens_and_current_word([1, 2])
        end

        it 'returns no chunks' do
          result = suggester.get_chunks_by_prior_tokens_and_current_word([1, 2])

          expect(result.length).to eq(0)
        end
      end
    end

    describe '.candidate_tokens_for_current_word' do
      #todo: write these tests
    end

    describe '.get_chunks_by_prior_tokens_only' do # rubocop:disable Metrics/BlockLength
      let(:max_suggestions) { Suggester::MAX_SUGGESTIONS }

      context 'when five candidates for all prior_tokens' do
        # there are 6 chunk candidates that start with [1, 2] - but we only want five of them
        let(:prior_token_ids) { [1, 2] }

        it 'calls database once' do
          expect(Token).to receive(:where).at_most(:once).and_call_original

          suggester.get_chunks_by_prior_tokens_only(prior_token_ids)
        end

        it 'returns five candidates' do
          chunks = suggester.get_chunks_by_prior_tokens_only(prior_token_ids)

          expect(chunks.length).to eq(max_suggestions)
        end

        it 'orders candidates correctly' do
          chunks = suggester.get_chunks_by_prior_tokens_only(prior_token_ids)

          expect(chunks[0]).to eq(chunk_the_has)       # count = 15
          expect(chunks[1]).to eq(chunk_the_ham)       # count = 10
          expect(chunks[2]).to eq(chunk_ending_in_hat) # count = 5
        end
      end

      context 'when less than five candidates for all prior_tokens' do
        # there are only 2 chunk candidates that start with [3, 2] - but there
        # are another two that starts with [2]. However, one of those is
        # 'heart' which we don't want to add twice.
        let(:prior_token_ids) { [3, 2] }

        it 'calls get_chunks_by_prior_tokens_only recursively' do
          expect(suggester).to receive(:get_chunks_by_prior_tokens_only).at_least(:twice).and_call_original
          expect(Chunk).to receive(:where).at_least(:twice).and_call_original

          suggester.get_chunks_by_prior_tokens_only(prior_token_ids)
        end

        it 'returns all the candidates' do
          chunks = suggester.get_chunks_by_prior_tokens_only(prior_token_ids)

          expect(chunks.length).to eq(3)
        end

        it 'orders candidates correctly' do
          # even though _heart has a count of 3, because it is less specific
          # than my_heart it should be second
          chunks = suggester.get_chunks_by_prior_tokens_only(prior_token_ids)

          expect(chunks[0]).to eq(chunk_my_heart) # count = 5
          expect(chunks[1]).to eq(chunk_my_hat)   # count = 1
          expect(chunks[2]).to eq(chunk__hearts)  # count = 3
        end
      end

      context 'when no prior_token_ids' do
        it 'returns empty relation' do
          prior_token_ids = []
          chunks = suggester.get_chunks_by_prior_tokens_only(prior_token_ids)

          expect(chunks.length).to eq(0)
        end
      end
    end

    describe 'get_token_id_candidates_from_chunks' do
      it 'returns an array of token ids' do
        candidate_chunks = Chunk.where('size = 3')

        token_ids = suggester.get_token_id_candidates_from_chunks(candidate_chunks)

        expect(token_ids.length).to eq(candidate_chunks.length)
        expect(token_ids).to include(token_ham.id)
      end

      it 'handles empty candidate_chunks' do
        candidate_chunks = Chunk.none

        token_ids = suggester.get_token_id_candidates_from_chunks(candidate_chunks)

        expect(token_ids.length).to eq(0)
      end
    end

    describe '.build_suggestions' do # rubocop:disable Metrics/BlockLength

      let!(:longer_chunk) { create(:chunk, language: language, count: 2, token_ids: [1, 2, 10, 2], size: 4) }
      let!(:candidate_chunks) do
        [longer_chunk, chunk_ending_in_hat, chunk_the_ham, chunk_the_has, chunk4, chunk5]
      end

      describe 'the candidates hash' do
        it 'contains a hash of the candidates' do
          result = suggester.build_suggestions(candidate_chunks)
          expect(result).to include(:candidates)
        end

        it 'has the expected number of candidates' do
          result = suggester.build_suggestions(candidate_chunks)[:candidates]

          expect(result.length).to eq(candidate_chunks.length)
        end

        it 'is ordered by chunk size' do
          result = suggester.build_suggestions(candidate_chunks)[:candidates]

          expect(result.first).to eq({ token_text: ' ', chunk_size: longer_chunk.size, count: 2 })
          expect(result.last).to eq({ token_text: 'hit', chunk_size: chunk5.size, count: 1 })
        end

        it 'contains probabilities', skip: 'Not sure if we need probabilities' do
          result = suggester.build_suggestions(candidate_chunks)[:candidates]
          expect(result.first[:probability]).to eq(longer_chunk)
        end
      end
      context 'analysis is also wanted' do
      end
    end
  end
end
