require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = %w( --require support/coverage )
  task.verbose = false
end

task :default => [:spec]
