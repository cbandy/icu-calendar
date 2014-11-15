# encoding: UTF-8

require File.expand_path('../lib/icu/calendar/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = 'icu-calendar'
  gem.version = ICU::Calendar::VERSION
  gem.summary = %q{FIXME}

  gem.author = 'Chris Bandy'
  gem.email = 'bandy.chris@gmail.com'
  gem.homepage = 'https://github.com/cbandy/icu-calendar'
  gem.license = 'Apache License Version 2.0'

  gem.files = %w( LICENSE README.md ) + Dir.glob('lib/**/*.rb')

  gem.add_development_dependency 'rspec', '>= 3.0'
  gem.add_runtime_dependency 'ffi'
  gem.required_ruby_version = '>= 1.9.3'
  gem.requirements << 'ICU 4.2 or greater, http://www.icu-project.org/'
end
