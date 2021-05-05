# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextMessage, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:text) }
    it { should belong_to(:language) }
  end
end
