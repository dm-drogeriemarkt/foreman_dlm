require 'test_plugin_helper'

module Host
  class ManagedTest < ActiveSupport::TestCase
    should have_many(:dlmlocks)
    should have_many(:dlmlock_events)
    should have_one(:dlm_facet)

    describe '#can_acquire_update_locks?' do
      let(:host) { FactoryBot.create(:host, :managed) }

      it 'should be true without a host parameter' do
        assert host.can_acquire_update_locks?
      end

      it 'should be true if parameter is true' do
        FactoryBot.create(:host_parameter, host: host, name: 'can_acquire_update_locks', value: 'true')
        assert host.can_acquire_update_locks?
      end

      it 'should be false if parameter is false' do
        FactoryBot.create(:host_parameter, host: host, name: 'can_acquire_update_locks', value: 'false')
        assert_not host.can_acquire_update_locks?
      end
    end

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
