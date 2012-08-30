
/* vim: set shiftwidth=2 tabstop=2: */

#include <rice/Array.hpp>
#include <rice/Data_Type.hpp>
#include <rice/Module.hpp>

namespace ruby {
	#include <ruby/encoding.h>
}

#include <unicode/calendar.h>
#include <unicode/errorcode.h>
#include <unicode/timezone.h>

class ErrorCode: public icu::ErrorCode
{
	protected:
		virtual void handleFailure() const
		{
			throw Rice::Exception(rb_eRuntimeError, u_errorName(errorCode));
		}
};

template<>
icu::UnicodeString from_ruby<icu::UnicodeString>(Rice::Object x)
{
	// FIXME handle encodings
	Rice::String s(x);
	return UNICODE_STRING(s.c_str(), s.length());
}

template<>
Rice::Object to_ruby<icu::UnicodeString>(icu::UnicodeString const &x)
{
	std::string dest;
	x.toUTF8String(dest);

	Rice::String result(dest);
	ruby::rb_enc_associate(result, ruby::rb_utf8_encoding());

	return result;
}

Rice::Array calendar_available_locales(Rice::Object /* class */)
{
	int32_t count = 0, i;
	const icu::Locale *locales = icu::Calendar::getAvailableLocales(count);
	Rice::Array result;

	for (i = 0; i < count; ++i)
		result.push(Rice::String(locales[i].getName()));

	return result;
}

Rice::String timezone_canonical_id(Rice::Object /* class */, Rice::String id)
{
	icu::UnicodeString result;
	ErrorCode status;

	icu::TimeZone::getCanonicalID(from_ruby<icu::UnicodeString>(id), result, status);

	return to_ruby(result);
}

Rice::Array timezone_enumeration(Rice::Object /* class */)
{
	const icu::UnicodeString *timezone;
	icu::StringEnumeration *timezones = icu::TimeZone::createEnumeration();
	Rice::Array result;
	ErrorCode status;

	timezone = timezones->snext(status);
	status.assertSuccess();

	while (timezone != NULL)
	{
		result.push(to_ruby(*timezone));

		timezone = timezones->snext(status);
		status.assertSuccess();
	}

	return result;
}

extern "C"
void Init_icu_calendar()
{
	Rice::Module rb_mICU = Rice::define_module("ICU");

	Rice::Data_Type<icu::Calendar> rb_cCalendar = rb_mICU.define_class("Calendar")
		.define_singleton_method("available_locales", &calendar_available_locales)
		.define_singleton_method("canonical_timezone_identifier", &timezone_canonical_id)
		.define_singleton_method("timezones", &timezone_enumeration);
}
