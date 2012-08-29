
/* vim: set shiftwidth=2 tabstop=2: */

#include <rice/Array.hpp>
#include <rice/Data_Type.hpp>
#include <rice/Module.hpp>

namespace ruby {
	#include <ruby/encoding.h>
}

#include <unicode/calendar.h>
#include <unicode/timezone.h>

template<>
Rice::Object to_ruby<icu::UnicodeString>(icu::UnicodeString const &x)
{
	std::string dest;
	x.toUTF8String(dest);

	Rice::String result(dest);
	ruby::rb_enc_associate(result, ruby::rb_utf8_encoding());

	return result;
}

Rice::Object calendar_available_locales(Rice::Object /* class */)
{
	int32_t count = 0, i;
	const icu::Locale *locales = icu::Calendar::getAvailableLocales(count);
	Rice::Array result;

	for (i = 0; i < count; ++i)
		result.push(Rice::String(locales[i].getName()));

	return result;
}

Rice::Object timezone_enumeration(Rice::Object /* class */)
{
	icu::StringEnumeration *timezones = icu::TimeZone::createEnumeration();
	const icu::UnicodeString *timezone;
	UErrorCode status;
	Rice::Array result;

	status = U_ZERO_ERROR;
	timezone = timezones->snext(status);

	while (timezone != NULL && U_SUCCESS(status))
	{
		result.push(to_ruby<icu::UnicodeString>(*timezone));

		status = U_ZERO_ERROR;
		timezone = timezones->snext(status);
	}

	return result;
}

extern "C"
void Init_icu_calendar()
{
	Rice::Module rb_mICU = Rice::define_module("ICU");

	Rice::Data_Type<icu::Calendar> rb_cCalendar = rb_mICU.define_class("Calendar")
		.define_singleton_method("available_locales", &calendar_available_locales)
		.define_singleton_method("timezones", &timezone_enumeration);
}
