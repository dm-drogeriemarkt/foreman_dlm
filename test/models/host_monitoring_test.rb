require 'test_plugin_helper'

class HostMonitoringTest < ActiveSupport::TestCase
  let(:host) { FactoryBot.create(:host, :managed, :with_monitoring) }
  let(:monitoring_mock) { mock('monitoring') }
  let(:exception) { ProxyAPI::ProxyException.new(host.monitoring_proxy.url, StandardError.new, 'Some error message') }

  setup do
    skip unless ForemanDlm.with_monitoring?
    User.current = users(:admin)
    Host::Managed.any_instance.stubs(:monitoring).returns(monitoring_mock)
    monitoring_mock.stubs(:query_host).returns({})
  end

  context 'a free and enabled DLM lock' do
    let(:dlmlock) { FactoryBot.create(:dlmlock) }

    test 'creates monitoring downtime' do
      monitoring_mock.expects(:set_downtime_host).once
      assert dlmlock.acquire!(host)
    end

    test 'does not fail on monitoring proxy error' do
      monitoring_mock.expects(:set_downtime_host).once.raises(exception)
      assert dlmlock.acquire!(host)
    end
  end

  context 'an acquired DLM lock' do
    let(:dlmlock) { FactoryBot.create(:dlmlock, :host => host) }

    test 'removes monitoring dowmtine' do
      monitoring_mock.expects(:del_downtime_host).once
      assert dlmlock.release!(host)
    end

    test 'does not fail on monitoring proxy error' do
      monitoring_mock.expects(:del_downtime_host).once.raises(exception)
      assert dlmlock.release!(host)
    end
  end
end
