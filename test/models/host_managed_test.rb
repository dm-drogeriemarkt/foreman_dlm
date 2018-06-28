require 'test_plugin_helper'

module Host
  class ManagedTest < ActiveSupport::TestCase
    should have_many(:dlmlocks)
  end
end
