# frozen_string_literal: true

require 'rails_helper'
RSpec.describe 'TextMessages', type: :feature do
  scenario 'User types some new text', js: true do
    visit '/text_messages/index'
  end
end
