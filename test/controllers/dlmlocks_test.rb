require 'test_plugin_helper'

class DlmlocksControllerTest < ActionController::TestCase
  test '#index' do
    FactoryBot.create(:dlmlock)
    get :index, {}, set_session_user
    assert_response :success
    assert_not_nil assigns('dlmlocks')
    assert_template 'index'
  end

  test '#index with no lock shows welcome page' do
    get :index, {}, set_session_user
    assert_response :success
    assert_template 'welcome'
  end

  test '#show' do
    dlmlock = FactoryBot.create(:dlmlock)
    get :show, { :id => dlmlock.id }, set_session_user
    assert_response :success
    assert_template 'show'
  end
end
