# frozen_string_literal: true

# Every text message needs a language associated with it so that we can make
# predicions based on the correct language
# TODO: Maybe add country codes
class Language < ApplicationRecord
  validates :language, uniqueness: { case_sensitive: true }
  validates_presence_of :language

  before_validation :titleize_language

  def titleize_language
    self.language = language.downcase.titleize if language
  end
end
