# frozen_string_literal: true

require 'test_plugin_helper'

class Api::V2::HostsControllerTest < ActionController::TestCase
  let(:host) { FactoryBot.create(:host, :managed, :with_dlm_facet) }

  test 'should get index with dlm_facet attributes' do
    host
    get :index
    assert_response :success
    results = ActiveSupport::JSON.decode(@response.body)
    hosts = results['results']
    assert_not_empty hosts
    host_with_facet = hosts.detect { |h| h['dlm_facet_attributes'].present? }
    assert_not_nil host_with_facet
    assert_equal host.dlm_facet.id, host_with_facet['dlm_facet_attributes']['id']
    assert_equal host.dlm_facet.last_checkin_at.to_s, host_with_facet['dlm_facet_attributes']['last_checkin_at']
  end

  test 'should show individual record with dlm_facet attributes' do
    get :show, params: { :id => host.to_param }
    assert_response :success
    show_response = ActiveSupport::JSON.decode(@response.body)
    assert_not_empty show_response
    assert_includes show_response.keys, 'dlm_facet_attributes'
    assert_equal host.dlm_facet.id, show_response['dlm_facet_attributes']['id']
    assert_equal host.dlm_facet.last_checkin_at.to_s, show_response['dlm_facet_attributes']['last_checkin_at']
  end
end
