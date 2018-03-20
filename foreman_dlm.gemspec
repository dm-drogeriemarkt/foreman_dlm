require File.expand_path('../lib/foreman_dlm/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'foreman_dlm'
  s.version     = ForemanDlm::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['Timo Goebel']
  s.email       = ['timo.goebel@dm.de']
  s.homepage    = 'https://github.com/timogoebel/foreman_dlm'
  s.summary     = 'Distributed Lock Manager for Foreman.'
  # also update locale/gemspec.rb
  s.description = 'Adds a Distributed Lock Manager to Foreman. This enables painless system updates for clusters.'

  s.files = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rdoc'
end
