FactoryBot.define do
  factory :dlmlock do
    sequence(:name) { |n| "Lock #{n}" }
    type 'Dlmlock::Update'
  end
end
