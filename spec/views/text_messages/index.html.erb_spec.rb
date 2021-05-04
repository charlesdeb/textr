# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'text_messages/index.html.erb', type: :view do
  context 'boiler plate [move to a feature spec]' do
    it 'has show analysis checkbox'
    it 'has language selector'
  end

  context 'content' do
    let(:language) { create(:language, language: 'Klingon') }
    before(:each) do
      assign(:languages, [language])
      assign(
        :text_messages, [create(:text_message, text: 'The rain in Spain falls mainly on the plain', language: language),
                         create(:text_message, text: 'Baby got blue eyes.', language: language)]
      )

      render
    end

    # not sure why we are testing this here and in a request spec...
    it 'shows previous text messages' do
      expect(rendered).to match /rain/
      expect(rendered).to match /Baby/
    end

    it 'shows language selector' do
      expect(rendered).to match /Klingon/
    end
  end
end
