# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChunkAnalyser, type: :model do # rubocop:disable Metrics/BlockLength
  let(:language) { create(:language) }
  let(:text_message) { create(:text_message, { text: 'hello world', language: language }) }

  describe '#initialize' do
    it 'sets text_message as an instance variable' do
      analyser = ChunkAnalyser.new(text_message)
      expect(analyser.instance_variable_get(:@text_message)).to be(text_message)
    end
  end

  describe '.analyse' do # rubocop:disable Metrics/BlockLength
    let(:analyser) { ChunkAnalyser.new(text_message) }
    let(:token_ids) { [1, 2, 3] } # a mock value

    before(:each) do
      # stub these methods
      allow(Token).to receive(:id_ise).and_return(token_ids)
      allow(analyser).to receive(:analyse_by_tokens)
    end

    describe 'breaks the text message into tokens' do
      it 'that are single characters' do
        analyser.analyse

        expect(Token).to have_received(:id_ise).with(text_message.text, :by_letter)
      end

      it 'that are single words (or punctuation marks)' do
        analyser.analyse

        expect(Token).to have_received(:id_ise).with(text_message.text, :by_word)
      end
    end

    it 'analyses the tokens' do
      expect(analyser).to receive(:analyse_by_tokens).with(token_ids).twice

      analyser.analyse
    end

    describe 'returns a hash for analysis results' do
      let(:output) { analyser.analyse }

      it 'by letter' do
        expect(output).to include(:by_letter)
        expect(output[:by_letter]).to include(:chunks)
        expect(output[:by_letter][:chunks]).to eq(token_ids.length)
        expect(output[:by_letter]).to include(:seconds_elapsed)
      end

      it 'by word' do
        expect(output).to include(:by_word)
        expect(output[:by_word]).to include(:chunks)
        expect(output[:by_word][:chunks]).to eq(token_ids.length)
        expect(output[:by_word]).to include(:seconds_elapsed)
      end
    end
  end

  describe '.analyse_by_tokens' do # rubocop:disable Metrics/BlockLength
    let(:analyser) { ChunkAnalyser.new(text_message) }

    before(:each) do
      allow(analyser).to receive(:count_chunks)
    end

    it 'counts the number of times chunks of tokens appear in the text_message (token_ids)' do
      token_ids = [1, 2, 3]
      expect(analyser).to receive(:count_chunks)

      analyser.analyse_by_tokens(token_ids)
    end

    describe 'runs over the different chunk sizes' do
      it 'for small text messages' do
        token_ids = [1, 2, 3, 4] # we can count chunks of size 2, 3 and 4

        analyser.analyse_by_tokens(token_ids)

        expect(analyser).to have_received(:count_chunks).with(token_ids, 2)
        expect(analyser).to have_received(:count_chunks).with(token_ids, 3)
        expect(analyser).to have_received(:count_chunks).with(token_ids, 4)
        expect(analyser).to_not have_received(:count_chunks).with(token_ids, 5)
      end

      it 'for long text messages' do
        token_ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] # we can count chunks of size 2, 3 and 4

        analyser.analyse_by_tokens(token_ids)

        expect(analyser).to have_received(:count_chunks).with(token_ids, 2)
        expect(analyser).to have_received(:count_chunks).with(token_ids, 8)
        expect(analyser).to_not have_received(:count_chunks).with(token_ids, 9)
      end
    end
  end

  describe '.count_chunks' do
    let(:analyser) { ChunkAnalyser.new(text_message) }
    let(:token_ids) { [1, 2, 3] }
    let(:chunk_size) { 2 }
    let(:chunks_hash) { { [1, 2] => 1, [2, 3] => 1 } }

    before(:each) do
      allow(analyser).to receive(:build_chunks_hash).with(token_ids, chunk_size).and_return(chunks_hash)
      allow(analyser).to receive(:upsert_chunks_hash)
    end

    it 'builds hash with the counts of the number of times the tokens in the chunk appear in token_ids' do
      expect(analyser).to receive(:build_chunks_hash).with(token_ids, chunk_size)

      analyser.count_chunks(token_ids, chunk_size)
    end

    it 'combines this hash of counts with counts from previously analysed text messages in the database' do
      expect(analyser).to receive(:upsert_chunks_hash).with(chunks_hash, chunk_size)

      analyser.count_chunks(token_ids, chunk_size)
    end
  end

  describe '.build_chunks_hash' do
    let(:analyser) { ChunkAnalyser.new(text_message) }

    describe 'counts the number of times each consecutive chunk of tokens appears in token_ids' do
      it 'handles build_chunks_hash([1, 2, 3, 4], 2)' do
        hash = analyser.build_chunks_hash([1, 2, 3], 2)
        expect(hash).to eq({ [1, 2] => 1, [2, 3] => 1 })
      end

      it 'handles build_chunks_hash([1, 2, 3, 4], 3)' do
        hash = analyser.build_chunks_hash([1, 2, 3, 4], 3)
        expect(hash).to eq({ [1, 2, 3] => 1, [2, 3, 4] => 1 })
      end

      it 'handles build_chunks_hash([1, 1, 1, 1], 2)' do
        hash = analyser.build_chunks_hash([1, 1, 1, 1], 2)
        expect(hash).to eq({ [1, 1] => 3 })
      end

      it 'handles build_chunks_hash([1,1,1,1],3)' do
        hash = analyser.build_chunks_hash([1, 1, 1, 1], 3)
        expect(hash).to eq({ [1, 1, 1] => 2 })
      end
    end
  end

  describe '.upsert_chunks_hash' do # rubocop:disable Metrics/BlockLength
    let(:analyser) { ChunkAnalyser.new(text_message) }

    context 'brand new hash counts' do
      let(:hash) { { [1, 1, 1] => 2, [1, 2, 3] => 1 } }
      let(:chunk_size) { 3 }

      before(:each) do
        analyser.upsert_chunks_hash(hash, chunk_size)
      end

      it 'inserts the Chunk records' do
        expect(Chunk.all.count).to eq(2)
      end
    end

    context 'existing hash counts' do
      let(:chunk_size) { 2 }

      let!(:prior_chunk) do
        create(:chunk, {
                 language: language, token_ids: [1, 2], count: 2, size: chunk_size
               })
      end

      let(:latest_chunks_hash) { { [1, 2] => 2 } }

      it 'combines current hash counts with past counts' do
        analyser.upsert_chunks_hash(latest_chunks_hash, chunk_size)

        expect(Chunk.all.count).to eq(1)
        chunk = Chunk.first
        expect(chunk.count).to eq(4)
      end
    end
  end
end
