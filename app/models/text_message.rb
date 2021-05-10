# frozen_string_literal: true

# A chunk of text that a user has entered
class TextMessage < ApplicationRecord
  validates_presence_of :text
  belongs_to :language

  # Entry point for generating text using the sentence chunk strategy
  #
  # Actual work is done by ChunkAnalyser class
  #
  # @return [Hash] with information about how the analysis went for
  #                different strategies
  def analyse
    analyser = ChunkAnalyser.new(self)

    analyser.analyse
  end
end
