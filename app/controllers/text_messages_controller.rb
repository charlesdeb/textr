# frozen_string_literal: true

class TextMessagesController < ApplicationController
  before_action :set_languages # , only: %i[show edit update destroy generate reanalyse]

  def create
    @text_message = TextMessage.new(text_params)

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
  # def generate_params
  #   params.permit(:chunk_size, :output_size, :id, :strategy)
  # end
end
