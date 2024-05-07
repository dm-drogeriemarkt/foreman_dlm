# frozen_string_literal: true

FactoryBot.define do
  factory :dlmlock_event, class: ::ForemanDlm::DlmlockEvent do
    dlmlock
    event_type { 'release' }
    host

    trait :old_event do
      after(:build) do |event|
        event.created_at = 2.weeks.ago
      end
    end
  end
end
