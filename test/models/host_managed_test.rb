require 'test_plugin_helper'

module Host
  class ManagedTest < ActiveSupport::TestCase
    should have_many(:dlmlocks)
    should have_many(:dlmlock_events)
    should have_one(:dlm_facet)

    context 'scoped search on' do
      context 'a host' do
        let(:host) { FactoryBot.create(:host, :with_dlm_facet) }
        setup do
          host
        end

        test 'can be searched by dlm checkin time' do
          results = Host.search_for('last_dlm_checkin_at < "2 weeks from now"')
          assert_includes results, host
        end
      end
    end
  end
end
