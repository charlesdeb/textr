class TextsController < ApplicationController
  def create
  end

  def index
    @texts = Text.all
  end
end
