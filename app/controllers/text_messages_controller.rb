# frozen_string_literal: true

# controller for TextMessages
class TextMessagesController < ApplicationController
  before_action :set_languages, only: %i[index]

  def create
    p text_params
    @text_message = TextMessage.new(text_params)
    @text_message.analyse

    if @text_message.save
      respond_to do |format|
        format.html do
          redirect_to text_messages_index_url
        end
      end
    end
  end

  def index
    @text_message = TextMessage.new
    @text_messages = TextMessage.all
  end

  def reset
    if TextMessage.delete_all && Token.delete_all

      respond_to do |format|
        format.html do
          redirect_to text_messages_index_url, notice: 'All learning data deleted.'
        end
      end
    end
  end

  def suggestions
    @current_message = suggestion_params['current_message']
    # @suggestions = Suggester.new(suggestion_params)

    respond_to do |format|
      format.js { render :index, layout: false }
      format.html do
        # suggestions is an ajax only action - just show the index again
        redirect_to text_messages_index_url
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_languages
    @languages = Language.all
  end

  # Only allow a list of trusted parameters through.
  def text_params
    params.require(:text_message).permit(:language_id, :text)
  end

  # Only allow a list of trusted parameters through.
  def suggestion_params
    params.permit(:current_message, :language_id)
  end
end
