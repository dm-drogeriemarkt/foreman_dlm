# frozen_string_literal: true

FactoryBot.define do
  factory :dlm_facet, class: 'ForemanDlm::DlmFacet' do
    sequence(:last_checkin_at) { |n| n.minutes.ago }
    host
  end
end
