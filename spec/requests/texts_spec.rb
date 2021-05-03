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
    before(:each) do
      create(:text, text: 'The rain in Spain falls mainly on the plain')
      create(:text, text: 'Baby got blue eyes.')

      get '/texts/index'
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'shows contents of texts' do
      assert_select('li', { text: /Spain/ })
      assert_select('li', { text: /Baby/ })
    end
  end
end
