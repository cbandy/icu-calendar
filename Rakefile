require 'bundler/gem_tasks'
require 'rake/extensiontask'
require 'rspec/core/rake_task'

Rake::ExtensionTask.new('icu_calendar') do |ext|
  ext.ext_dir = 'ext/icu/calendar'
  ext.lib_dir = 'lib/icu'
end

RSpec::Core::RakeTask.new(:spec)

task :default => [:clean, :compile, :spec]
