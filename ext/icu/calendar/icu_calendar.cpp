
/* vim: set shiftwidth=2 tabstop=2: */

#include <rice/Array.hpp>
#include <rice/Data_Type.hpp>
#include <rice/Module.hpp>
#include <unicode/calendar.h>

namespace ICU = icu;

Rice::Object calendar_available_locales(Rice::Object /* class */)
{
	int32_t count = 0, i;
	const ICU::Locale *locales = ICU::Calendar::getAvailableLocales(count);
	Rice::Array result;

	for (i = 0; i < count; ++i)
		result.push(Rice::String(locales[i].getName()));

	return result;
}

extern "C"
void Init_icu_calendar()
{
	Rice::Module rb_mICU = Rice::define_module("ICU");

	Rice::Data_Type<ICU::Calendar> rb_cCalendar = rb_mICU.define_class("Calendar")
		.define_singleton_method("available_locales", &calendar_available_locales);
}
