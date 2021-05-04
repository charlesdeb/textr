# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Texts', type: :request do
  describe 'POST /create' do
    it 'returns http success' do
      post '/texts/create'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /index' do
    let(:klingon) { create(:language, language: 'Klingon') }

    before(:each) do
      # create some historic text messages
      create(:text, text: 'The rain in Spain falls mainly on the plain', language: klingon)
      create(:text, text: 'Baby got blue eyes.', language: klingon)

      get '/texts/index'
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
