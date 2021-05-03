# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'texts/index.html.erb', type: :view do
  context 'boiler plate' do
    it 'has show analysis checkbox'
    it 'has language selector'
  end

  context 'content' do
    it 'shows previous text messages' do
      assign(:texts, [
               create(:text, text: 'The rain in Spain falls mainly on the plain'),
               create(:text, text: 'Baby got blue eyes.')
             ])
      render
      expect(rendered).to match /rain/
      expect(rendered).to match /Baby/
    end
  end
end
