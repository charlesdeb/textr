# frozen_string_literal: true

class TextMessage < ApplicationRecord
  validates_presence_of :text
  belongs_to :language
end
