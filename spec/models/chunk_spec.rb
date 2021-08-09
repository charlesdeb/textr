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

  describe '#exclude_candidate_token_ids (scope)' do
    let(:language) { create(:language, language: 'Klingon') }

    before(:each) do
      create(:chunk, token_ids: [1, 2, 3], language_id: language.id)
      create(:chunk, token_ids: [1, 2, 4], language_id: language.id)
    end

    it 'excludes token_ids that exist' do
      token_ids = [3]
      expect(Chunk.all.count).to eq(2)

      chunks = Chunk.exclude_candidate_token_ids(token_ids, 3)

      expect(chunks.count).to eq(1)
    end

    it 'doesn\'t exclude anything if token_ids is empty' do
      token_ids = []
      chunks = Chunk.exclude_candidate_token_ids(token_ids, 3)
      expect(chunks.count).to eq(2)
    end
  end

  describe '#by_current_word' do
  end
end
