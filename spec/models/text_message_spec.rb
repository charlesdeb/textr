# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextMessage, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:text) }
    it { should belong_to(:language) }
  end

  describe '#analyse' do
    let(:text_message) { create(:text_message, { text: 'hello world' }) }
    let(:chunk_analyser) { instance_double('ChunkAnalyser') }

    it 'delegates to the ChunkAnalyser class' do
      allow(ChunkAnalyser).to receive(:new).with(text_message).and_return(chunk_analyser)
      expect(chunk_analyser).to receive(:analyse)

      text_message.analyse

      expect(ChunkAnalyser).to have_received(:new).with(text_message)
    end
  end
end
