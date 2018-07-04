require 'test_plugin_helper'

module ForemanDlm
  class DlmlockEventTest < ActiveSupport::TestCase
    should belong_to(:dlmlock)
    should belong_to(:host)
    should belong_to(:user)
  end
end
