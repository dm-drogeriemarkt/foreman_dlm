FactoryBot.define do
  factory :dlmlock, class: ::ForemanDlm::Dlmlock do
    sequence(:name) { |n| "Lock #{n}" }
    type 'ForemanDlm::Dlmlock::Update'
  end
end
