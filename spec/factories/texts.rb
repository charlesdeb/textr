# frozen_string_literal: true

FactoryBot.define do
  factory :text do
    text { 'A piece of text' }
    association :language
  end
end
