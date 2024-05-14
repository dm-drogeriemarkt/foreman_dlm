# frozen_string_literal: true

require File.expand_path('lib/foreman_dlm/version', __dir__)

Gem::Specification.new do |s|
  s.name        = 'foreman_dlm'
  s.version     = ForemanDlm::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['Timo Goebel']
  s.email       = ['timo.goebel@dm.de']
  s.homepage    = 'https://github.com/dm-drogeriemarkt/foreman_dlm'
  s.summary     = 'Distributed Lock Manager for Foreman.'
  # also update locale/gemspec.rb
  s.description = 'Adds a Distributed Lock Manager to Foreman. This enables painless system updates for clusters.'

  s.required_ruby_version = '>= 2.5', '< 4'

  s.files = Dir['{app,config,db,lib,locale}/**/*', 'contrib/systemd/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'is_foreman_plugin' => 'true',
  }

  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'theforeman-rubocop', '~> 0.1.2'
end
