
/* vim: set shiftwidth=2 tabstop=2: */

#include <rice/Module.hpp>
#include <unicode/calendar.h>

namespace ICU = icu;

extern "C"
void Init_icu_calendar()
{
	Rice::Module rb_mICU = Rice::define_module("ICU");

	Rice::Data_Type<ICU::Calendar> rb_cCalendar =
		Rice::define_class_under(rb_mICU, "Calendar");
}
