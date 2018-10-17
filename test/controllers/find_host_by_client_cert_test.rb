require_relative '../test_plugin_helper'

class FindHostByClientCertTest < ActionController::TestCase
  tests 'api/v2/dlmlocks'

  def described_class
    Api::V2::DlmlocksController
  end

  context 'with ssl settings' do
    setup do
      Setting[:ssl_client_dn_env] = 'SSL_CLIENT_S_DN'
      Setting[:ssl_client_verify_env] = 'SSL_CLIENT_VERIFY'
    end

    let(:host) { as_admin { FactoryBot.create(:host, :managed) } }

    context 'with api credentials' do
      test 'certificate with dn permits access' do
        @request.env['HTTPS'] = 'on'
        @request.env['SSL_CLIENT_VERIFY'] = 'NONE'

        get :index

        assert @controller.send(:require_client_cert_or_login)
        assert_nil @controller.detected_host
      end

      test 'certificate with dn permits access' do
        @request.env['HTTPS'] = 'on'
        @request.env['SSL_CLIENT_S_DN'] = "CN=#{host.name},DN=example,DN=com"
        @request.env['SSL_CLIENT_VERIFY'] = 'SUCCESS'

        get :index

        assert @controller.send(:require_client_cert_or_login)
        assert_equal host, @controller.detected_host
      end
    end

    context 'without api credentials' do
      setup do
        User.current = nil
        reset_api_credentials
      end

      test 'certificate with dn permits access' do
        @request.env['HTTPS'] = 'on'
        @request.env['SSL_CLIENT_S_DN'] = "CN=#{host.name},DN=example,DN=com"
        @request.env['SSL_CLIENT_VERIFY'] = 'SUCCESS'

        get :index

        assert @controller.send(:require_client_cert_or_login)
        assert_equal host, @controller.detected_host
      end

      test 'certificate with unknown dn denies access' do
        @request.env['HTTPS'] = 'on'
        @request.env['SSL_CLIENT_S_DN'] = 'CN=doesnotexist.example.com,DN=example,DN=com'
        @request.env['SSL_CLIENT_VERIFY'] = 'SUCCESS'

        get :index

        assert_equal false, @controller.send(:require_client_cert_or_login)
        assert_nil @controller.detected_host
      end

      test 'invalid certificate denies access' do
        @request.env['HTTPS'] = 'on'
        @request.env['SSL_CLIENT_S_DN'] = "CN=#{host.name},DN=example,DN=com"
        @request.env['SSL_CLIENT_VERIFY'] = 'GENEROUS'

        get :index

        assert_equal false, @controller.send(:require_client_cert_or_login)
        assert_nil @controller.detected_host
      end

      test 'no certificate denies access' do
        @request.env['HTTPS'] = 'on'
        @request.env['SSL_CLIENT_VERIFY'] = 'NONE'

        get :index

        assert_equal false, @controller.send(:require_client_cert_or_login)
        assert_nil @controller.detected_host
      end
    end
  end
end
