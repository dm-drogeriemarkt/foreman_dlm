require 'test_plugin_helper'

module ForemanDlm
  class DlmFacetTest < ActiveSupport::TestCase
    setup do
      User.current = users(:admin)
    end

    subject { FactoryBot.create(:dlm_facet) }
    should belong_to(:host)
    should validate_presence_of(:host)
  end
end
