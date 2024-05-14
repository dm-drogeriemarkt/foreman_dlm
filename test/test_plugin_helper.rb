# frozen_string_literal: true

# This calls the main test_helper in Foreman-core
require 'test_helper'

# Add plugin to FactoryBot's paths
FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')

# Add factories of external plugin dependencies
FactoryBot.definition_file_paths << "#{ForemanMonitoring::Engine.root}/test/factories" if ForemanDlm.with_monitoring?

# Reload factory paths
FactoryBot.reload
