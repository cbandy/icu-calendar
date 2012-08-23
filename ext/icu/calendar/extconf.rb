require 'mkmf'

if /darwin/ =~ RUBY_PLATFORM
  have_library('icucore')
else
  have_library('icuuc')
  have_library('icui18n')
end

create_makefile('icu/icu_calendar')
