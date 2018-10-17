require_relative '../../test_plugin_helper'

module ForemanDlm
  class DlmlockEventTest < ActiveSupport::TestCase
    should belong_to(:dlmlock)
    should belong_to(:host)
    should belong_to(:user)

    test 'should expire lock events' do
      event_count = 5
      FactoryBot.create_list(:dlmlock_event, event_count)
      FactoryBot.create_list(:dlmlock_event, event_count, :old_event)
      assert_difference(-> { ForemanDlm::DlmlockEvent.count }, -1 * event_count) do
        ForemanDlm::DlmlockEvent.expire(created_before: 7.days, batch_size: 2, sleep_time: 0.0001)
      end
      assert_equal event_count, ForemanDlm::DlmlockEvent.count
    end
  end
end
