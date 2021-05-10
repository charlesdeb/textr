# frozen_string_literal: true

# TODO: fix this
FactoryBot.define do
  factory :chunk do
    size { 1 }
    count { 1 }
    association :language
    token_ids { [1, 2, 3] }
  end
end
