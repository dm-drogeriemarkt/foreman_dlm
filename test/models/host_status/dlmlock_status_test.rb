# frozen_string_literal: true

require 'test_plugin_helper'

class DlmlockStatusTest < ActiveSupport::TestCase
  let(:host) { FactoryBot.create(:host, :managed) }

  describe '#to_status' do
    test 'should return STALE if host has any stale dlmlocks' do
      now = Time.now.utc

      travel_to now do
        FactoryBot.create(:dlmlock, :locked, host: host, updated_at: now - 5.hours)
        status = host.get_status(HostStatus::DlmlockStatus)

        assert_not_empty host.dlmlocks.stale
        assert_equal HostStatus::DlmlockStatus::STALE, status.to_status
      end
    end

    test 'should return OK if host has no stale dlmlocks' do
      status = host.get_status(HostStatus::DlmlockStatus)

      assert_empty host.dlmlocks.stale
      assert_equal HostStatus::DlmlockStatus::OK, status.to_status
    end
  end

  describe '#relevant?' do
    test 'should return true if host has any dlmlocks' do
      FactoryBot.create(:dlmlock, host: host)
      status = host.get_status(HostStatus::DlmlockStatus)

      assert_not_empty host.dlmlocks
      assert status.relevant?
    end

    test 'should return false if host has no dlmlocks' do
      status = host.get_status(HostStatus::DlmlockStatus)

      assert_empty host.dlmlocks
      assert_not status.relevant?
    end
  end
end
