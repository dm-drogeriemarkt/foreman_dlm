require 'test_plugin_helper'

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
    assert_redirected_to dlmlocks_url
    refute Dlmlock.exists?(dlmlock.id)
  end
end
