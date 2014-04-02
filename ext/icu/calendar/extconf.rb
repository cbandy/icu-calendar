require 'mkmf'

$defs.push('-DU_NO_DEFAULT_INCLUDE_UTF_HEADERS=1')

idir, ldir = dir_config('icu')

find_header('unicode/ucal.h') || abort
find_header('unicode/utypes.h') || abort
find_header('unicode/uversion.h') || abort

create_makefile('icu/icu_constants')
