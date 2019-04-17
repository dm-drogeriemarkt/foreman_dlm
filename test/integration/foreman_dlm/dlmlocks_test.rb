# frozen_string_literal: true

require 'integration_test_plugin_helper'

class DlmlocksTest < IntegrationTestWithJavascript
  setup do
    Setting::Dlm.load_defaults
    User.current = users(:admin)
  end

  test 'the index page works' do
    FactoryBot.create_list(:dlmlock, 10)
    assert_index_page(foreman_dlm_dlmlocks_path, 'Distributed Locks')
  end

  test 'the search bar has autocomplete' do
    skip if Gem::Version.new(Foreman::Version.new.notag) < Gem::Version.new('1.20')
    FactoryBot.create_list(:dlmlock, 10)

    visit foreman_dlm_dlmlocks_path

    search_bar = page.first('#search-bar')
    search_bar.first('input').set('ho')

    list = search_bar.find_all('a.dropdown-item').map(&:text)
    assert_includes list, 'host'
  end
end
