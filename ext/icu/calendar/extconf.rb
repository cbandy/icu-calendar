require 'mkmf-rice'

$defs.push('-DU_USING_ICU_NAMESPACE=0')

dir_config('icu')

have_header('unicode/calendar.h')

have_library('icuuc')
have_library('icui18n')

create_makefile('icu/icu_calendar')
