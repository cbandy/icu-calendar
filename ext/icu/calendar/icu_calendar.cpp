
/* vim: set shiftwidth=2 tabstop=2: */

#include <rice/Array.hpp>
#include <rice/Data_Type.hpp>
#include <rice/Module.hpp>

namespace ruby
{
	#include <ruby/encoding.h>
}

#include <unicode/calendar.h>
#include <unicode/errorcode.h>
#include <unicode/timezone.h>

namespace
{
	Rice::Data_Type<icu::Calendar> rb_cICUCalendar;
	Rice::Class  rb_eICURuntimeError;
	Rice::Module rb_mICU;
}

class ErrorCode: public icu::ErrorCode
{
	protected:
		virtual void handleFailure() const
		{
			throw Rice::Exception(rb_eICURuntimeError, u_errorName(errorCode));
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

template<>
Rice::Object to_ruby<icu::StringEnumeration*>(icu::StringEnumeration* const &x)
{
	const icu::UnicodeString *item;
	Rice::Array result;
	ErrorCode status;

	item = x->snext(status);
	status.assertSuccess();

	while (item != NULL)
	{
		result.push(to_ruby(*item));

		item = x->snext(status);
		status.assertSuccess();
	}

	delete x;
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

Rice::Array country_timezones(Rice::Object /* class */, Rice::Object country)
{
	const char *str = country.is_nil() ? NULL : Rice::String(country).c_str();

	return to_ruby(icu::TimeZone::createEnumeration(str));
}

extern "C"
void Init_icu_calendar()
{
	rb_mICU = Rice::define_module("ICU");

	rb_cICUCalendar = rb_mICU.define_class("Calendar")
		.define_singleton_method("available_locales", &calendar_available_locales)
		.define_singleton_method("canonical_timezone_identifier", &timezone_canonical_id)
		.define_singleton_method("country_timezones", &country_timezones)
		.define_singleton_method("offset_timezones",
				(icu::StringEnumeration* (*)(int32_t))
				&icu::TimeZone::createEnumeration)
		.define_singleton_method("timezones",
				(icu::StringEnumeration* (*)())
				&icu::TimeZone::createEnumeration);

	rb_eICURuntimeError = rb_cICUCalendar.define_class("RuntimeError", rb_eRuntimeError);
}
