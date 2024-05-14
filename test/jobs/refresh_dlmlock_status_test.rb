# frozen_string_literal: true

require 'test_plugin_helper'

class RefreshDlmlockStatusTest < ActiveJob::TestCase
  let(:host) { FactoryBot.create(:host, :managed) }

  test 'should refresh dlmlock status' do
    Host::Managed.any_instance.expects(:refresh_dlmlock_status).once
    perform_enqueued_jobs { ForemanDlm::RefreshDlmlockStatus.perform_later(host.id) }
  end
end
