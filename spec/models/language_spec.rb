require 'rails_helper'

RSpec.describe Language, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:language) }

    it 'titleizes languages' do
      language = Language.new(language: 'klingon')
      language.validate
      expect(language.language).to eq('Klingon')
    end

    it 'ensures unique languages' do
      Language.create(language: 'klingon')
      language2 = Language.new(language: 'KLINGON')
      expect(language2).to_not be_valid
    end
  end
end
