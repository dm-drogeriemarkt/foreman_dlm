module ForemanDlm
  module DlmFacetHostExtensions
    extend ActiveSupport::Concern

    included do
      has_one :dlm_facet, class_name: '::ForemanDlm::DlmFacet', foreign_key: :host_id, inverse_of: :host, dependent: :destroy

      accepts_nested_attributes_for :dlm_facet, update_only: true, reject_if: ->(attrs) { attrs.values.compact.empty? }

      scoped_search on: :last_checkin_at, relation: :dlm_facet, rename: :last_dlm_checkin_at, complete_value: true, only_explicit: true
    end
  end
end
