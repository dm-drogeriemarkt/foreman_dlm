# frozen_string_literal: true

require 'test_plugin_helper'

class UserTest < ActiveSupport::TestCase
  should have_many(:dlmlock_events)
end
