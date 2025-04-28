# frozen_string_literal: true

require 'test_plugin_helper'
require 'integration_test_helper'

class DlmlocksTest < IntegrationTestWithJavascript
  setup do
    User.current = users(:admin)
  end

  test 'the index page works' do
    FactoryBot.create_list(:dlmlock, 10)
    assert_index_page(foreman_dlm_dlmlocks_path, 'Distributed Locks')
  end

  test 'the search bar has autocomplete' do
    FactoryBot.create_list(:dlmlock, 10)

    visit foreman_dlm_dlmlocks_path

    search_bar = page.first('.foreman-search-bar')
    search_bar.first('input').set('ho')

    autocomplete_list = page.first('div[data-ouia-component-id="search-autocomplete-menu"]')
    version = Foreman::Version.new
    list = if version.major.to_i == 3 && version.minor.to_i <= 14
             autocomplete_list.find_all('span.pf-c-menu__item-text').map(&:text)
           else
             autocomplete_list.find_all('span.pf-v5-c-menu__item-text').map(&:text)
           end

    assert_includes list, 'host'
  end
end
