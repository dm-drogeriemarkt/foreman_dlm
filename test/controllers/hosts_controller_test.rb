# frozen_string_literal: true

require 'test_plugin_helper'

class HostsControllerTest < ActionController::TestCase
  let(:host) { FactoryBot.create(:host, :with_dlm_facet) }

  test '#show shows dlm locks of that host' do
    FactoryBot.create_list(:dlmlock, 2, host: host)
    get :show, params: { :id => host.to_param }, session: set_session_user
    assert_response :success
    assert_match(/id='pagelet-id-locks'/, @response.body)
  end
end
