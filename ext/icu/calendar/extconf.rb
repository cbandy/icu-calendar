require 'mkmf-rice'

def with_cc_cplusplus
  original = $CFLAGS.dup
  $CFLAGS << ' -x c++'
  yield
ensure
  $CFLAGS = original
end

$defs.push('-DU_USING_ICU_NAMESPACE=0')

idir, ldir = dir_config('icu')

with_cc_cplusplus do
  find_header('unicode/calendar.h') || abort
  find_header('unicode/timezone.h') || abort
end

have_library('icuuc',   'u_errorName', 'unicode/utypes.h') || abort
have_library('icui18n', 'ucal_open',   'unicode/ucal.h')   || abort

create_makefile('icu/icu_calendar')
