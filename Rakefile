require 'bundler/gem_tasks'
require 'rake/extensiontask'
require 'rspec/core/rake_task'

Rake::ExtensionTask.new('icu_constants') do |ext|
  ext.ext_dir = 'ext/icu/calendar'
  ext.lib_dir = 'lib/icu/calendar'
end

RSpec::Core::RakeTask.new(:spec)

task :default => [:clean, :compile, :spec]

desc 'Valgrind all specs'
task :valgrind do
  opts = %w(
    --error-limit=no
    --num-callers=50
    --partial-loads-ok=yes
    --undef-value-errors=no
  )
  sh *['valgrind', opts, %w(ruby -S rspec)].flatten
end
