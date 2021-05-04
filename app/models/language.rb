# frozen_string_literal: true

class Language < ApplicationRecord
  validates :language, uniqueness: true
end
