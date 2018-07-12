module ForemanDlm
  class DlmFacet < ApplicationRecord
    include Facets::Base

    validates :host, presence: true, allow_blank: false
  end
end
