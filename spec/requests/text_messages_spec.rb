# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TextMessages', type: :request do # rubocop:disable Metrics/BlockLength
  let(:language) { create(:language, language: 'Klingon') }

  def create_dummy_data
    # create some historic text messages
    create(:text_message, text: 'The rain in Spain falls mainly on the plain', language: language)
    create(:text_message, text: 'Baby got blue eyes.', language: language)
  end

  describe 'POST /create' do # rubocop:disable Metrics/BlockLength
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
    before(:each) do
      create_dummy_data
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
      assert_select('select option', { text: language.language })
      # assert_select("select option:contains(aaa#{language.language})")
    end
  end

  describe 'DELETE /reset' do
    before(:each) do
      create_dummy_data
      delete '/text_messages/reset'
    end

    it 'deletes all tokens and text_messages' do
      expect(Token.count).to eq 0
      expect(TextMessage.count).to eq 0
    end

    it 'shows confirmation message' do
      expect(flash[:notice]).to eq('All learning data deleted.')
    end
  end

  describe 'GET /suggest' do # rubocop:disable Metrics/BlockLength
    context 'ajax request' do # rubocop:disable Metrics/BlockLength
      let(:params) do
        { text_message: 'the', language_id: language.id.to_s, show_analysis: 'false' }
      end

      let(:suggester_suggestions) do
        { candidates: [
          { token_text: 'Groovy', probability: 0.75, chunk_size: 6 },
          { token_text: 'Monkey', probability: 0.15, chunk_size: 4 }
        ] }
      end

      let(:suggester) { double(Suggester, suggest: suggester_suggestions) }

      it 'returns http success' do
        get text_messages_suggest_path,
            params: params, xhr: true

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('text/javascript')
      end

      it 'handles no candidates' do
        suggester_suggestions = { candidates: [] }
        suggester = double(Suggester, suggest: suggester_suggestions)
        allow(Suggester).to receive(:new).and_return(suggester)

        get text_messages_suggest_path,
            params: params, xhr: true

        expect(@response.body).to match(/Sorry, no suggestions for that input/)
      end

      it 'shows the candidates' do
        allow(Suggester).to receive(:new).and_return(suggester)
        get text_messages_suggest_path,
            params: params, xhr: true

        expect(@response.body).to match(/Groovy/)
        expect(@response.body).to match(/Monkey/)
        expect(@response.body).to match(/75%/)
        expect(@response.body).to match(/15%/)
        # assert_select 'oo', @response.body
      end

      it 'shows analysis when requested but there is none' do
        params[:show_analysis] = 'true'
        suggester_suggestions[:analysis] = []
        suggester = double(Suggester, suggest: suggester_suggestions)
        allow(Suggester).to receive(:new).and_return(suggester)

        get text_messages_suggest_path,
            params: params, xhr: true

        expect(@response.body).to match(/Sorry, there were no analysis results/)
      end

      it 'shows analysis when requested and there is some' do # rubocop:disable Metrics/BlockLength
        params[:show_analysis] = 'true'
        suggester_suggestions[:analysis] = [
          { chunk_size: 6,
            chunk: 'The cat in ', candidate_token_texts: [
              { token_text: 'the', probability: 0.75 },
              { token_text: 'a', probability: 0.15 },
              { token_text: 'this', probability: 0.05 }
            ] },
          { chunk_size: 5,
            chunk: ' cat in ', candidate_token_texts: [
              { token_text: 'the', probability: 0.75 },
              { token_text: 'a', probability: 0.15 },
              { token_text: 'this', probability: 0.05 }
            ] },
          { chunk_size: 4,
            chunk: 'cat in ', candidate_token_texts: [
              { token_text: 'the', probability: 0.75 },
              { token_text: 'a', probability: 0.15 },
              { token_text: 'this', probability: 0.05 }
            ] }
        ]

        suggester = double(Suggester, suggest: suggester_suggestions)
        allow(Suggester).to receive(:new).and_return(suggester)

        get text_messages_suggest_path,
            params: params, xhr: true

        expect(@response.body).to match(/The cat in /)
      end

      it 'does not show analysis when not required' do
        params[:show_analysis] = 'false'

        get text_messages_suggest_path,
            params: params, xhr: true

        expect(@response.body).to match(/html\(""\)/)
      end
    end
  end
end
