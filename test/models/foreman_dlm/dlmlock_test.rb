# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanDlm
  class DlmlockTest < ActiveSupport::TestCase
    setup do
      User.current = users(:admin)
    end

    should belong_to(:host)
    should have_many(:dlmlock_events)

    subject { FactoryBot.create(:dlmlock) }
    should validate_presence_of(:name)
    should validate_uniqueness_of(:name)

    let(:host1) { FactoryBot.create(:host, :managed) }
    let(:host2) { FactoryBot.create(:host, :managed) }

    class HostWithCallbacks < ::Host::Managed
      attr_accessor :callbacks

      def initialize(*attributes, &block)
        super
        @callbacks = []
      end

      after_lock :callback1
      after_unlock :callback2

      def callback1
        Rails.logger.debug "callback1 executed for #{self} (#{self.class})"
        callbacks << 'callback1'
      end

      def callback2
        Rails.logger.debug "callback2 executed for #{self} (#{self.class})"
        callbacks << 'callback2'
      end
    end

    let(:host1_with_callbacks) { HostWithCallbacks.create(:name => 'test1.example.com') }
    let(:host2_with_callbacks) { HostWithCallbacks.create(:name => 'test2.example.com') }

    context 'a free and enabled DLM lock' do
      let(:dlmlock) { FactoryBot.create(:dlmlock) }

      test 'should be enabled and unlocked' do
        assert dlmlock.enabled?
        assert_not dlmlock.disabled?
        assert_not dlmlock.locked?
        assert_not dlmlock.taken?
      end

      test 'can be acquired' do
        assert_nil dlmlock.host
        assert dlmlock.acquire!(host1)
        assert_equal host1, dlmlock.reload.host
      end

      test 'can be released' do
        assert_nil dlmlock.host
        assert dlmlock.release!(host1)
        assert_nil dlmlock.reload.host
      end

      test 'creates a dlmlock_event on acquisition by owner' do
        assert_difference -> { DlmlockEvent.count }, 1 do
          assert dlmlock.acquire!(host1)
        end

        event = DlmlockEvent.last
        assert_equal 'acquire', event.event_type
        assert_equal host1.id, event.host_id
        assert_equal users(:admin).id, event.user_id
        assert_equal dlmlock.id, event.dlmlock_id
      end

      test 'triggers after_lock callback' do
        host = HostWithCallbacks.new
        host.name = 'test.example.com'
        host.save
        assert dlmlock.acquire!(host)
        assert_equal ['callback1'], host.callbacks
      end

      context 'with a parameter disabeling the locking' do
        setup do
          FactoryBot.create(:host_parameter, host: host1, name: 'can_acquire_update_locks', value: 'false')
        end

        test 'can not be acquired' do
          assert_nil dlmlock.host
          assert_not dlmlock.acquire!(host1)
          assert_nil dlmlock.reload.host
        end
      end
    end

    context 'a free and disabled DLM lock' do
      let(:dlmlock) { FactoryBot.create(:dlmlock, :enabled => false) }

      test 'should be disabled and unlocked' do
        assert_not dlmlock.enabled?
        assert dlmlock.disabled?
        assert_not dlmlock.locked?
        assert_not dlmlock.taken?
      end

      test 'can not be acquired' do
        assert_nil dlmlock.host
        assert_not dlmlock.acquire!(host1)
        assert_nil dlmlock.reload.host
      end

      test 'can not be released' do
        assert_nil dlmlock.host
        assert_not dlmlock.release!(host1)
        assert_nil dlmlock.reload.host
      end

      test 'triggers no callbacks' do
        host = HostWithCallbacks.new
        host.name = 'test.example.com'
        host.save
        assert_not dlmlock.release!(host)
        assert_empty host.callbacks
      end
    end

    context 'an acquired DLM lock' do
      let(:dlmlock) { FactoryBot.create(:dlmlock, :host => host1) }

      test 'should be enabled and locked' do
        assert dlmlock.enabled?
        assert_not dlmlock.disabled?
        assert dlmlock.locked?
        assert dlmlock.taken?
        assert dlmlock.locked_by?(host1)
        assert dlmlock.acquired_by?(host1)
      end

      test 'can be acquired by owner' do
        assert_equal host1, dlmlock.host
        assert dlmlock.acquire!(host1)
        assert_equal host1, dlmlock.reload.host
      end

      test 'can not be acquired by other host' do
        assert_equal host1, dlmlock.host
        assert_not dlmlock.acquire!(host2)
        assert_equal host1, dlmlock.reload.host
      end

      test 'can be released by owner' do
        assert_equal host1, dlmlock.host
        assert dlmlock.release!(host1)
        assert_nil dlmlock.reload.host
      end

      test 'can not be released by other host' do
        assert_equal host1, dlmlock.host
        assert_not dlmlock.release!(host2)
        assert_equal host1, dlmlock.reload.host
      end

      test 'records audit change on release by owner' do
        dlmlock
        assert_difference -> { DlmlockEvent.count }, 1 do
          assert dlmlock.release!(host1)
        end

        event = DlmlockEvent.last
        assert_equal 'release', event.event_type
        assert_equal host1.id, event.host_id
        assert_equal users(:admin).id, event.user_id
        assert_equal dlmlock.id, event.dlmlock_id
      end

      test 'records no audit change on acquisition by owner' do
        assert_no_difference "Audit.where(auditable_type: 'ForemanDlm::Dlmlock', action: 'update').count" do
          assert dlmlock.acquire!(host1)
        end
      end

      test 'triggers after_unlock callback on release by owner' do
        host = HostWithCallbacks.new
        host.name = 'test.example.com'
        host.save
        dlmlock.host = host
        dlmlock.save
        assert dlmlock.release!(host)
        assert_equal ['callback2'], host.callbacks
      end

      test 'triggers no callbacks on release attempt by other host' do
        assert host1_with_callbacks
        assert host2_with_callbacks
        dlmlock.update(:host => host1_with_callbacks)
        assert_not dlmlock.release!(host2_with_callbacks)
        assert_empty host1_with_callbacks.callbacks
        assert_empty host2_with_callbacks.callbacks
      end

      test 'triggers no callbacks on acquiry attempt by owner' do
        assert host1_with_callbacks
        dlmlock.update(:host => host1_with_callbacks)
        assert dlmlock.acquire!(host1_with_callbacks)
        assert_empty host1_with_callbacks.callbacks
      end
    end

    context 'scoped search' do
      test 'can be searched by name' do
        dlmlock = FactoryBot.create(:dlmlock)
        assert_equal Dlmlock::Update.find(dlmlock.id), Dlmlock.search_for("name ~ #{dlmlock.name}").first
      end
    end

    describe '#locked' do
      subject { Dlmlock.locked }

      it 'includes only Distributed Locks that are locked' do
        locked = FactoryBot.create(:dlmlock, :locked)
        not_locked = FactoryBot.create(:dlmlock)

        assert_includes subject, locked
        assert_not_includes subject, not_locked
      end
    end

    describe '#stale' do
      subject { Dlmlock.stale }

      it 'includes only Distributed Locks that are stale' do
        now = Time.now.utc

        travel_to now do
          stale = FactoryBot.create(:dlmlock, :locked, updated_at: now - 5.hours)
          not_stale = FactoryBot.create(:dlmlock, :locked, updated_at: now)
          not_locked = FactoryBot.create(:dlmlock)

          assert_includes subject, stale
          assert_not_includes subject, not_stale
          assert_not_includes subject, not_locked
        end
      end
    end

    context '#log_events' do
      let(:dlmlock) { FactoryBot.create(:dlmlock) }

      test 'logs acquire event' do
        assert_difference -> { DlmlockEvent.count }, 1 do
          dlmlock.acquire!(host1)
        end

        event = DlmlockEvent.last
        assert_equal 'acquire', event.event_type
        assert_equal host1, event.host
      end

      test 'logs disable event' do
        assert_difference -> { DlmlockEvent.count }, 1 do
          dlmlock.disable!
        end

        event = DlmlockEvent.last
        assert_equal 'disable', event.event_type
      end

      test 'logs enable event' do
        dlmlock.update(enabled: false)

        assert_difference -> { DlmlockEvent.count }, 1 do
          dlmlock.enable!
        end

        event = DlmlockEvent.last
        assert_equal 'enable', event.event_type
      end

      test 'logs failed event' do
        dlmlock.acquire!(host1)

        assert_difference -> { DlmlockEvent.count }, 1 do
          dlmlock.acquire!(host2)
        end

        event = DlmlockEvent.last
        assert_equal 'fail', event.event_type
        assert_equal host1, event.host
      end

      test 'logs release event' do
        dlmlock.acquire!(host1)

        assert_difference -> { DlmlockEvent.count }, 1 do
          assert dlmlock.release!(host1)
        end

        event = DlmlockEvent.last
        assert_equal 'release', event.event_type
        assert_equal host1, event.host
      end
    end
  end
end
