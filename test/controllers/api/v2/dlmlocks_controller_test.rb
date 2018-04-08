require 'test_plugin_helper'

class Api::V2::DlmlocksControllerTest < ActionController::TestCase
  let(:host1) { as_admin { FactoryBot.create(:host, :managed) } }
  let(:host2) { as_admin { FactoryBot.create(:host, :managed) } }

  context 'with user authentication' do
    context '#index' do
      test 'should show dlmlocks' do
        dlmlock = FactoryBot.create(:dlmlock, :host => host1)
        get :index
        assert_response :success
        body = ActiveSupport::JSON.decode(@response.body)
        results = body['results']
        assert results
        entry = results.detect { |e| e['id'] == dlmlock.id }
        assert entry
        assert_equal dlmlock.name, entry['name']
        assert_equal dlmlock.type, entry['type']
        assert_equal dlmlock.enabled, entry['enabled']
        assert_equal dlmlock.host_id, entry['host_id']
      end
    end

    context '#create' do
      test 'should create dlmlock' do
        assert_difference('Dlmlock.unscoped.count') do
          post :create, valid_attrs_with_root
        end
        assert_response :success
        body = ActiveSupport::JSON.decode(@response.body)
        dlmlock = Dlmlock.find(body['id'])
        assert dlmlock
        assert_equal valid_attrs['name'], dlmlock.name
        assert_equal valid_attrs['type'], dlmlock.type
        assert_equal true, dlmlock.enabled
        assert_nil dlmlock.host
      end
    end

    context '#show' do
      test 'should show individual record with host' do
        dlmlock = FactoryBot.create(:dlmlock, :host => host1)
        get :show, :id => dlmlock.to_param
        assert_response :success
        body = ActiveSupport::JSON.decode(@response.body)
        refute_empty body
        assert_equal dlmlock.name, body['name']
        assert_equal dlmlock.type, body['type']
        assert_equal true, body['enabled']
        assert_equal host1.id, body['host_id']
      end

      test 'should show individual record that is disabled' do
        dlmlock = FactoryBot.create(:dlmlock, :enabled => false)
        get :show, :id => dlmlock.to_param
        assert_response :success
        body = ActiveSupport::JSON.decode(@response.body)
        refute_empty body
        assert_equal dlmlock.name, body['name']
        assert_equal dlmlock.type, body['type']
        assert_equal false, body['enabled']
        assert_nil body['host_id']
      end

      test 'should show individual record by name' do
        dlmlock = FactoryBot.create(:dlmlock, :host => host1)
        get :show, :id => dlmlock.name
        assert_response :success
        body = ActiveSupport::JSON.decode(@response.body)
        refute_empty body
        assert_equal dlmlock.id, body['id']
        assert_equal dlmlock.name, body['name']
        host = body['host']
        assert host
        assert_equal host1.name, host['name']
        refute host.key?('self')
      end

      test 'should not find dlmlock with invalid id' do
        get :show, :id => 9_999_999
        assert_response :not_found
      end
    end

    context '#update' do
      test 'should update dlmlock' do
        dlmlock = FactoryBot.create(:dlmlock)
        put :update, :id => dlmlock.to_param, :dlmlock => valid_attrs.merge(:host_id => host1.id, :enabled => false)
        assert_response :success
        dlmlock.reload
        assert_equal valid_attrs['name'], dlmlock.name
        assert_equal valid_attrs['type'], dlmlock.type
        assert_equal false, dlmlock.enabled
        assert_equal host1.id, dlmlock.host_id
      end
    end

    context '#destroy' do
      test 'should destroy dlmlock' do
        dlmlock = FactoryBot.create(:dlmlock)
        assert_difference('Dlmlock.unscoped.count', -1) do
          delete :destroy, :id => dlmlock.to_param
        end
        assert_response :success
        assert_equal 0, Dlmlock.where(:id => dlmlock.id).count
      end
    end

    context '#acquire' do
      test 'should deny access' do
        dlmlock = FactoryBot.create(:dlmlock)
        put :acquire, :id => dlmlock.to_param
        assert_response :forbidden
        assert_nil dlmlock.reload.host
      end
    end

    context '#release' do
      test 'should deny access' do
        dlmlock = FactoryBot.create(:dlmlock, :host => host2)
        delete :release, :id => dlmlock.to_param
        assert_response :forbidden
        assert_equal host2, dlmlock.reload.host
      end
    end
  end

  context 'with client cert' do
    setup do
      User.current = nil
      reset_api_credentials

      Setting[:ssl_client_dn_env] = 'SSL_CLIENT_S_DN'
      Setting[:ssl_client_verify_env] = 'SSL_CLIENT_VERIFY'

      @request.env['HTTPS'] = 'on'
      @request.env['SSL_CLIENT_S_DN'] = "CN=#{host1.name},DN=example,DN=com"
      @request.env['SSL_CLIENT_VERIFY'] = 'SUCCESS'
    end

    context '#index' do
      test 'should deny access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        get :index, :id => dlmlock.to_param
        assert_response :unauthorized
      end
    end

    context '#create' do
      test 'should deny access' do
        as_admin { FactoryBot.create(:dlmlock) }
        post :create, valid_attrs_with_root
        assert_response :unauthorized
      end
    end

    context '#update' do
      test 'should deny access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        put :update, :id => dlmlock.to_param, :dlmlock => valid_attrs
        assert_response :unauthorized
      end
    end

    context '#destroy' do
      test 'should deny access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        delete :destroy, :id => dlmlock.to_param
        assert_response :unauthorized
        assert_equal 1, as_admin { Dlmlock.where(:id => dlmlock.id).count }
      end
    end

    context '#show' do
      test 'should show individual free lock' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        get :show, :id => dlmlock.to_param
        assert_response :success
        body = ActiveSupport::JSON.decode(@response.body)
        refute_empty body
        assert_equal dlmlock.name, body['name']
        assert_equal dlmlock.type, body['type']
        assert_equal true, body['enabled']
        assert_nil body['host_id']
        assert_nil body['host']
      end

      test 'should show individual acquired lock by me' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock, :host => host1) }
        get :show, :id => dlmlock.to_param
        assert_response :success
        body = ActiveSupport::JSON.decode(@response.body)
        refute_empty body
        assert_equal dlmlock.name, body['name']
        assert_equal dlmlock.type, body['type']
        assert_equal true, body['enabled']
        assert_equal host1.id, body['host_id']
        host = body['host']
        assert host
        assert_equal host1.name, host['name']
        assert_equal true, host['self']
      end

      test 'should show individual acquired lock by other' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock, :host => host2) }
        get :show, :id => dlmlock.to_param
        assert_response :success
        body = ActiveSupport::JSON.decode(@response.body)
        refute_empty body
        assert_equal dlmlock.name, body['name']
        assert_equal dlmlock.type, body['type']
        assert_equal true, body['enabled']
        assert_equal host2.id, body['host_id']
        host = body['host']
        assert host
        assert_equal host2.name, host['name']
        assert_equal false, host['self']
      end
    end

    context '#acquire' do
      test 'should acquire empty dlmlock' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        put :acquire, :id => dlmlock.to_param
        assert_response :success
        assert_equal host1, as_admin { dlmlock.reload.host }
      end

      test 'should acquire own dlmlock' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock, :host => host1) }
        put :acquire, :id => dlmlock.to_param
        assert_response :success
        assert_equal host1, as_admin { dlmlock.reload.host }
      end

      test 'should not acquire foreign dlmlock' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock, :host => host2) }
        put :acquire, :id => dlmlock.to_param
        assert_response :precondition_failed
        assert_equal host2, as_admin { dlmlock.reload.host }
      end

      test 'should transparently create non-existing dlmlock' do
        lockname = 'Test Lock'
        assert_equal 0, as_admin { Dlmlock.where(:name => lockname).count }
        put :acquire, :id => lockname
        assert_response :success
        dlmlock = as_admin { Dlmlock.find_by(:name => lockname) }
        assert_equal lockname, dlmlock.name
        assert_equal host1, dlmlock.host
      end
    end

    context '#release' do
      test 'should release empty dlmlock' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        delete :release, :id => dlmlock.to_param
        assert_response :success
        assert_nil as_admin { dlmlock.reload.host }
      end

      test 'should release own dlmlock' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock, :host => host1) }
        delete :release, :id => dlmlock.to_param
        assert_response :success
        assert_nil as_admin { dlmlock.reload.host }
      end

      test 'should not acquire foreign dlmlock' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock, :host => host2) }
        delete :release, :id => dlmlock.to_param
        assert_response :precondition_failed
        assert_equal host2, as_admin { dlmlock.reload.host }
      end

      test 'should transparently create non-existing dlmlock' do
        lockname = 'Test Lock'
        assert_equal 0, as_admin { Dlmlock.where(:name => lockname).count }
        delete :release, :id => lockname
        assert_response :success
        dlmlock = as_admin { Dlmlock.find_by(:name => lockname) }
        assert_equal lockname, dlmlock.name
        assert_nil dlmlock.host
      end
    end
  end

  context 'without any credentials' do
    setup do
      User.current = nil
      reset_api_credentials
    end

    context '#index' do
      test 'should deny access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        get :index, :id => dlmlock.to_param
        assert_response :unauthorized
      end
    end

    context '#show' do
      test 'should deny access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        get :show, :id => dlmlock.to_param
        assert_response :unauthorized
      end
    end

    context '#create' do
      test 'should deny access' do
        as_admin { FactoryBot.create(:dlmlock) }
        post :create, valid_attrs_with_root
        assert_response :unauthorized
      end
    end

    context '#update' do
      test 'should deny access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        put :update, :id => dlmlock.to_param, :dlmlock => valid_attrs
        assert_response :unauthorized
      end
    end

    context '#destroy' do
      test 'should deny access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        delete :destroy, :id => dlmlock.to_param
        assert_response :unauthorized
        assert_equal 1, as_admin { Dlmlock.where(:id => dlmlock.id).count }
      end
    end

    context '#acquire' do
      test 'should deny access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        put :acquire, :id => dlmlock.to_param
        assert_response :unauthorized
        assert_nil as_admin { dlmlock.reload.host }
      end
    end

    context '#release' do
      test 'should deny access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock, :host => host2) }
        delete :release, :id => dlmlock.to_param
        assert_response :unauthorized
        assert_equal host2, as_admin { dlmlock.reload.host }
      end
    end
  end

  private

  def valid_attrs
    {
      'name' => 'testlock',
      'type' => 'Dlmlock::Update'
    }
  end

  def valid_attrs_with_root(extra_attrs = {})
    { :dlmlock => valid_attrs.merge(extra_attrs) }
  end
end
