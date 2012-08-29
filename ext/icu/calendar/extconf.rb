require 'mkmf-rice'

$defs.push('-DU_USING_ICU_NAMESPACE=0')

idir, ldir = dir_config('icu')

# terrible hack for mkmf C++ support
begin
  if ldir && $LIBPATH.last == ldir
    $LIBPATH.pop
    $DEFLIBPATH.unshift(ldir)
  end

  find_header('bits/c++config.h', '/usr/lib/gcc/x86_64-pc-linux-gnu/4.5.3/include/g++-v4/x86_64-pc-linux-gnu')
  find_header('string', '/usr/lib/gcc/x86_64-pc-linux-gnu/4.5.3/include/g++-v4')
end

have_header('unicode/calendar.h')
have_header('unicode/timezone.h')

have_library('icuuc')
have_library('icui18n')

create_makefile('icu/icu_calendar')
