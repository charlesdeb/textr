# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Chunk, type: :model do
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
end
