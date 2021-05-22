# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Token, type: :model do # rubocop:disable Metrics/BlockLength
  describe 'validations' do
    it { should validate_length_of(:text).is_at_least(1) }
    it { should validate_uniqueness_of(:text).case_insensitive }
  end

  describe '::id_ise' do # rubocop:disable Metrics/BlockLength
    let(:text_message) { create(:text_message) }
    let(:strategy) { :by_letter }
    let(:token_texts) { %w[a b c] }

    before(:each) do
      # stub methods
      allow(Token).to receive(:validate_strategy)
      allow(Token).to receive(:split_into_token_texts).with(text_message.text, strategy).and_return(token_texts)
      allow(Token).to receive(:token_texts_to_token_ids).with(token_texts)
    end

    it 'requires a known strategy' do
      Token.id_ise(text_message, strategy)

      expect(Token).to have_received(:validate_strategy).with(strategy)
    end

    it 'handles text messages with no text' do
      ['', nil].each do |text|
        text_message.text = text
        expect(Token.id_ise(text_message, :by_word)).to eq([])
      end
    end

    it 'breaks the text into tokens according to strategy' do
      expect(Token).to receive(:split_into_token_texts).with(text_message.text, strategy)

      Token.id_ise(text_message, strategy)
    end

    it 'stores tokens in the database' do
      expect(Token).to receive(:save_token_texts).with(token_texts)

      Token.id_ise(text_message, strategy)
    end

    it 'returns an array of IDs' do
      expect(Token).to receive(:token_texts_to_token_ids).with(token_texts)

      Token.id_ise(text_message, strategy)
    end
  end

  describe '::split_into_token_texts' do # rubocop:disable Metrics/BlockLength
    it 'requires a known strategy' do
      expect(Token).to receive(:validate_strategy)

      Token.split_into_token_texts('the', :strategy)
    end

    context ':by_letter splits the text into an array of letters' do
      let(:strategy) { :by_letter }

      it 'handles: "the"' do
        result = Token.split_into_token_texts('the', strategy)
        expect(result).to eq(%w[t h e])
      end

      it 'handles: " ttt ! "' do
        result = Token.split_into_token_texts(' ttt ! ', strategy)
        expect(result).to eq([' ', 't', 't', 't', ' ', '!', ' '])
      end

      it 'handles: "  t  t  " (removes multiple spaces)' do
        result = Token.split_into_token_texts('  t  t  ', strategy)
        expect(result).to eq([' ', 't', ' ', 't', ' '])
      end
    end

    context ':by_word splits the text into an array of words and punctuation' do
      let(:strategy) { :by_word }

      it 'handles: hey, dude!' do
        result = Token.split_into_token_texts('hey, dude!', strategy)
        expect(result).to eq(['hey', ',', ' ', 'dude', '!'])
      end

      it 'handles: hey,  dude!! (double space, exclamation mark)' do
        result = Token.split_into_token_texts('hey,  dude!!', strategy)
        expect(result).to eq(['hey', ',', ' ', 'dude', '!'])
      end

      it "handles: hey hey'" do
        result = Token.split_into_token_texts('hey hey', strategy)
        expect(result).to eq(['hey', ' ', 'hey'])
      end

      it "handles: hey, I said 'dude!'" do
        result = Token.split_into_token_texts("hey, I said 'dude!'", strategy)
        expect(result).to eq(['hey', ',', ' ', 'I', ' ', 'said',
                              ' ', '\'', 'dude', '!', '\''])
      end
    end
  end

  describe '::save_token_texts' do # rubocop:disable Metrics/BlockLength
    it 'adds the right number of tokens' do
      token_texts = %w[the hat]
      Token.save_token_texts(token_texts)
      expect(Token.count).to eq(2)
    end

    it 'handles spaces' do
      token_texts = ['the', ' ', 'hat']
      Token.save_token_texts(token_texts)
      expect(Token.count).to eq(3)
    end

    it 'handles duplicate tokens in the text' do
      token_texts = %w[the hat hat]
      Token.save_token_texts(token_texts)
      expect(Token.count).to eq(2)
    end

    it "it doesn't add duplicate tokens from a previous analysis" do
      # Add the 'hat' token
      Token.create!({ text: 'hat', created_at: DateTime.now })

      # Try to add 'hat#' again
      token_texts = %w[the hat]
      Token.save_token_texts(token_texts)
      expect(Token.count).to eq(2)
    end

    it 'handles letters' do
      token_texts = %w[a b c]
      Token.save_token_texts(token_texts)
      expect(Token.count).to eq(3)
    end
  end

  describe '::token_texts_to_token_ids' do
    before(:each) do
      current_time = DateTime.now
      Token.create!({ id: 1, text: 'the', created_at: current_time })
      Token.create!({ id: 2, text: ' ', created_at: current_time })
      Token.create!({ id: 3, text: 'hat', created_at: current_time })
    end

    it 'works' do
      token_texts = ['the', ' ', 'hat']
      result = Token.token_texts_to_token_ids(token_texts)
      expect(result).to eq([1, 2, 3])
    end

    it 'handles duplicates' do
      token_texts = ['the', ' ', 'hat', ' ', 'hat']
      result = Token.token_texts_to_token_ids(token_texts)
      expect(result).to eq([1, 2, 3, 2, 3])
    end

    it 'handles missing tokens' do
      token_texts = ['the', ' ', 'cat']
      expect { Token.token_texts_to_token_ids(token_texts) }.to raise_error(/Unknown token/)
    end
  end

  describe '::token_ids_to_token_texts' do
    before(:each) do
      current_time = DateTime.now
      Token.create!({ id: 1, text: 'the', created_at: current_time })
      Token.create!({ id: 2, text: ' ', created_at: current_time })
      Token.create!({ id: 3, text: 'hat', created_at: current_time })
    end

    it 'works' do
      token_ids = [1, 2, 3]
      result = Token.token_ids_to_token_texts(token_ids)
      expect(result).to eq(['the', ' ', 'hat'])
    end

    it 'handles duplicates' do
      token_ids = [1, 2, 3, 2, 3]
      result = Token.token_ids_to_token_texts(token_ids)
      expect(result).to eq(['the', ' ', 'hat', ' ', 'hat'])
    end

    it 'handles missing tokens' do
      token_ids = [1, 2, 4]
      expect { Token.token_ids_to_token_texts(token_ids) }.to raise_error(/Unknown token id/)
    end
  end

  describe '::validate_strategy' do
    it 'raises error for an unknown strategy' do
      expect do
        Token.validate_strategy(:zoop_zoop)
      end.to raise_error('Invalid strategy :zoop_zoop for Token.id_ise. Choose either :by_letter or :by_word')
    end

    it 'requires a known strategy' do
      %i[by_letter by_word].each do |strategy|
        expect do
          Token.validate_strategy(strategy)
        end.to_not raise_error
      end
    end
  end
end
