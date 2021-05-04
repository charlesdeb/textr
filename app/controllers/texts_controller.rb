class TextsController < ApplicationController
  def create
  end

  def index
    @languages = Language.all
    @texts = Text.all
  end
end
