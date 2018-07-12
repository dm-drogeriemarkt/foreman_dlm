FactoryBot.modify do
  factory :host do
    trait :with_dlm_facet do
      association :dlm_facet, :factory => :dlm_facet, :strategy => :build
    end
  end
end
