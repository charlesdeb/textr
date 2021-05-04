# frozen_string_literal: true

FactoryBot.define do
  factory :text_message do
    text { 'A piece of text' }
    association :language
  end
end
