FactoryBot.define do
  factory :dlmlock, class: ::ForemanDlm::Dlmlock::Update do
    sequence(:name) { |n| "Lock #{n}" }
    type { 'ForemanDlm::Dlmlock::Update' }

    trait :locked do
      host
    end
  end
end
