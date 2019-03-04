require 'test_plugin_helper'

class Api::V2::DlmlockEventsControllerTest < ActionController::TestCase
  let(:host) { as_admin { FactoryBot.create(:host, :managed) } }

  context 'with user authentication' do
    context '#index' do
      test 'should return the dlmlock_events for a given dlm_lock' do
        expected_size = 3

        # A random dlmlock with events, that should not be in the response.
        dlmlock1 = FactoryBot.create(:dlmlock, host: host)
        FactoryBot.create_list(:dlmlock_event, 2, dlmlock: dlmlock1)

        dlmlock = FactoryBot.create(:dlmlock, host: host)
        FactoryBot.create_list(:dlmlock_event, expected_size, dlmlock: dlmlock)

        expected_ids = dlmlock.dlmlock_events.pluck(:id).sort
        expected_keys = ['id', 'event_type', 'created_at', 'updated_at']

        get :index, params: { dlmlock_id: dlmlock.id }
        assert_response :success

        body = ActiveSupport::JSON.decode(@response.body)
        assert_equal expected_size, body['total']
        assert_equal expected_keys, body['results'].first.keys
        assert_equal expected_ids, body['results'].map { |event| event['id'] }.sort
      end
    end
  end

  context 'as user with required permissions' do
    let(:permissions) { Permission.where(name: ['view_dlmlocks', 'view_dlmlock_events']) }
    let(:role) { FactoryBot.create(:role, permissions: permissions) }
    let(:user) { FactoryBot.create(:user, roles: [role]) }

    setup do
      User.current = user
      reset_api_credentials
    end

    context '#index' do
      test 'should allow access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        get :index, params: { dlmlock_id: dlmlock.id }
        assert_response :success
      end
    end
  end

  context 'as user without required permissions' do
    let(:user) { FactoryBot.create(:user, roles: []) }

    setup do
      User.current = user
      reset_api_credentials
    end

    context '#index' do
      test 'should deny access' do
        dlmlock = as_admin { FactoryBot.create(:dlmlock) }
        get :index, params: { dlmlock_id: dlmlock.id }
        assert_response :forbidden
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
        get :index, params: { dlmlock_id: dlmlock.id }
        assert_response :unauthorized
      end
    end
  end
end
