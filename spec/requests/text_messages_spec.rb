# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TextMessages', type: :request do # rubocop:disable Metrics/BlockLength
  describe 'POST /create' do # rubocop:disable Metrics/BlockLength
    let(:language) { create(:language, language: 'Klingon') }
    let(:valid_attributes) do
      { text: 'A new text message', language_id: language.id }
    end

    it 'returns http success' do
      post text_messages_create_path, params: { text_message: valid_attributes }
      expect(response).to have_http_status(:redirect)
    end

    it 'renders the index' do
      post text_messages_create_path, params: { text_message: valid_attributes }
      expect(response).to redirect_to(text_messages_index_url)
    end

    it 'adds the new text to the database' do
      expect do
        post text_messages_create_path, params: { text_message: valid_attributes }
      end.to change(TextMessage, :count).by(1)
    end

    it 'adds chunk analysis to the database' do
      expect do
        post text_messages_create_path, params: { text_message: valid_attributes }
      end.to change(Chunk, :count).by_at_least(1)
    end

    it 'adds tokens to the database' do
      expect do
        post text_messages_create_path, params: { text_message: valid_attributes }
      end.to change(Token, :count).by_at_least(1)
    end
  end

  describe 'GET /index' do
    let(:klingon) { create(:language, language: 'Klingon') }

    before(:each) do
      # create some historic text messages
      create(:text_message, text: 'The rain in Spain falls mainly on the plain', language: klingon)
      create(:text_message, text: 'Baby got blue eyes.', language: klingon)

      get '/text_messages/index'
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'shows contents of texts' do
      assert_select('li', { text: /Spain/ })
      assert_select('li', { text: /Baby/ })
    end

    it 'shows language drop-down' do
      # assert_select('select option', { text: 'Klingon' })
      assert_select("select option:contains(#{klingon.language})")
    end
  end
end
