require 'test_plugin_helper'

module ForemanDlm
  class DlmlocksControllerTest < ActionController::TestCase
    test '#index' do
      FactoryBot.create(:dlmlock)
      get :index, session: set_session_user
      assert_response :success
      assert_not_nil assigns('dlmlocks')
      assert_template 'index'
    end

    test '#index with no lock shows welcome page' do
      get :index, session: set_session_user
      assert_response :success
      assert_template 'welcome'
    end

    test '#show' do
      dlmlock = FactoryBot.create(:dlmlock)
      get :show, params: { :id => dlmlock.id }, session: set_session_user
      assert_response :success
      assert_template 'show'
    end

    test '#destroy' do
      dlmlock = FactoryBot.create(:dlmlock)
      delete :destroy, params: { :id => dlmlock.id }, session: set_session_user
      assert_redirected_to foreman_dlm_dlmlocks_url
      refute Dlmlock.exists?(dlmlock.id)
    end

    test '#enable' do
      dlmlock = FactoryBot.create(:dlmlock, enabled: false)
      put :enable, params: { :id => dlmlock.id }, session: set_session_user
      assert_redirected_to foreman_dlm_dlmlocks_url
      assert dlmlock.reload.enabled?
    end

    test '#disable' do
      dlmlock = FactoryBot.create(:dlmlock, enabled: true)
      put :disable, params: { :id => dlmlock.id }, session: set_session_user
      assert_redirected_to foreman_dlm_dlmlocks_url
      assert dlmlock.reload.disabled?
    end

    test '#release' do
      host = FactoryBot.create(:host)
      dlmlock = FactoryBot.create(:dlmlock, host: host)
      put :release, params: { :id => dlmlock.id }, session: set_session_user
      assert_redirected_to foreman_dlm_dlmlocks_url
      refute dlmlock.reload.taken?
    end
  end
end
