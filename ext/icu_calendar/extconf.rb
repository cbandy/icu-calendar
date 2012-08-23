require 'mkmf'

have_library('icui18n') && create_makefile('icu_calendar/icu_calendar')
