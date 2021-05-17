# frozen_string_literal: true

require 'rails_helper'
RSpec.describe 'TextMessages', type: :feature do
  let(:message) { 'zoop' }
  scenario 'User types some new text', js: true do
    pending 'wait till model is written'
    visit '/text_messages/index'
    fill_in 'text_message_text', with: message

    # TODO: for real suggestions
    expect(page).to have_text("Suggestions? Not yet, but curent message is #{message}")
  end

  context 'show analysis', js: true do
    before(:each) do
      visit '/text_messages/index'
    end

    scenario 'is selected' do
      check(id: 'show_analysis_')
      fill_in 'text_message_text', with: message
      expect(page).to have_css('h4', text: /Chunk size/)
    end

    scenario 'is not selected' do
      fill_in 'text_message_text', with: message
      expect(page).to_not have_text('Some analysis')
    end
  end
end
