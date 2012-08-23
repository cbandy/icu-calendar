# encoding: UTF-8

require File.expand_path('../lib/icu_calendar/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = 'icu_calendar'
  gem.version = ICU::Calendar::VERSION
  gem.summary = %q{FIXME}
  gem.description = %q{FIXME}

  gem.author = 'Chris Bandy'
  gem.email = 'bandy.chris@gmail.com'
  gem.homepage = 'FIXME'
  gem.licenses = ['FIXME']

  gem.extensions << 'ext/icu_calendar/extconf.rb'
  gem.files = Dir.glob('lib/**/*')
  gem.test_files = Dir.glob('spec/**/*_spec.rb')

  gem.add_development_dependency 'rake-compiler'
  gem.add_development_dependency 'rspec'
  gem.required_ruby_version = '>= 1.9.2'
end
