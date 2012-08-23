require 'bundler/gem_tasks'
require 'rake/extensiontask'
require 'rspec/core/rake_task'

Rake::ExtensionTask.new('icu_calendar') do |ext|
  ext.lib_dir = 'lib/icu_calendar'
end

RSpec::Core::RakeTask.new(:spec => [:clean, :compile])
