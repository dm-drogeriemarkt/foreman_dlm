require 'rake/testtask'

# Tests
namespace :test do
  desc 'Test ForemanDlm'
  Rake::TestTask.new(:foreman_dlm) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

namespace :foreman_dlm do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_dlm) do |task|
        task.patterns = ["#{ForemanDlm::Engine.root}/app/**/*.rb",
                         "#{ForemanDlm::Engine.root}/lib/**/*.rb",
                         "#{ForemanDlm::Engine.root}/test/**/*.rb"]
      end
    rescue StandardError
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_dlm'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_dlm']

load 'tasks/jenkins.rake'
Rake::Task['jenkins:unit'].enhance ['test:foreman_dlm', 'foreman_dlm:rubocop'] if Rake::Task.task_defined?(:'jenkins:unit')
