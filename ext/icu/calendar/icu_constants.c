/* vim: set shiftwidth=2 tabstop=2: */

#include "ruby.h"
#include "unicode/ucal.h"
#include "unicode/uloc.h"
#include "unicode/utypes.h"
#include "unicode/uversion.h"

#define push_enum(array, symbol, value) do {\
	rb_ary_push(array, ID2SYM(rb_intern(symbol)));\
	rb_ary_push(array, INT2NUM(value));\
} while (0)

static VALUE
icu_calendar_am_pm_enum(VALUE module)
{
	VALUE result = rb_ary_new2(2);
	push_enum(result, "am", UCAL_AM);
	push_enum(result, "pm", UCAL_PM);
	return result;
}

static VALUE
icu_calendar_attribute_enum(VALUE module)
{
	VALUE result = rb_ary_new2(5);
	push_enum(result, "lenient",                    UCAL_LENIENT);
	push_enum(result, "first_day_of_week",          UCAL_FIRST_DAY_OF_WEEK);
	push_enum(result, "minimal_days_in_first_week", UCAL_MINIMAL_DAYS_IN_FIRST_WEEK);
#if U_ICU_VERSION_MAJOR_NUM >= 49
	push_enum(result, "repeated_wall_time", UCAL_REPEATED_WALL_TIME);
	push_enum(result, "skipped_wall_time",  UCAL_SKIPPED_WALL_TIME);
#endif
	return result;
}

static VALUE
icu_calendar_calendar_type_enum(VALUE module)
{
	VALUE result = rb_ary_new2(2);
	push_enum(result, "default",   UCAL_DEFAULT);
	push_enum(result, "gregorian", UCAL_GREGORIAN);
	return result;
}

static VALUE
icu_calendar_date_field_enum(VALUE module)
{
	VALUE result = rb_ary_new2(25);
	push_enum(result, "era",                  UCAL_ERA);
	push_enum(result, "year",                 UCAL_YEAR);
	push_enum(result, "month",                UCAL_MONTH);
	push_enum(result, "week_of_year",         UCAL_WEEK_OF_YEAR);
	push_enum(result, "week_of_month",        UCAL_WEEK_OF_MONTH);
	push_enum(result, "date",                 UCAL_DATE);
	push_enum(result, "day_of_year",          UCAL_DAY_OF_YEAR);
	push_enum(result, "day_of_month",         UCAL_DAY_OF_MONTH);
	push_enum(result, "day_of_week",          UCAL_DAY_OF_WEEK);
	push_enum(result, "day_of_week_in_month", UCAL_DAY_OF_WEEK_IN_MONTH);
	push_enum(result, "am_pm",                UCAL_AM_PM);
	push_enum(result, "hour",                 UCAL_HOUR);
	push_enum(result, "hour_of_day",          UCAL_HOUR_OF_DAY);
	push_enum(result, "minute",               UCAL_MINUTE);
	push_enum(result, "second",               UCAL_SECOND);
	push_enum(result, "millisecond",          UCAL_MILLISECOND);
	push_enum(result, "milliseconds_in_day",  UCAL_MILLISECONDS_IN_DAY);
	push_enum(result, "zone_offset",          UCAL_ZONE_OFFSET);
	push_enum(result, "dst_offset",           UCAL_DST_OFFSET);
	push_enum(result, "year_woy",             UCAL_YEAR_WOY);
	push_enum(result, "dow_local",            UCAL_DOW_LOCAL);
	push_enum(result, "extended_year",        UCAL_EXTENDED_YEAR);
	push_enum(result, "julian_day",           UCAL_JULIAN_DAY);
	push_enum(result, "is_leap_month",        UCAL_IS_LEAP_MONTH);
	push_enum(result, "field_count",          UCAL_FIELD_COUNT);
	return result;
}

static VALUE
icu_calendar_day_of_week_enum(VALUE module)
{
	VALUE result = rb_ary_new2(7);
	push_enum(result, "sunday",    UCAL_SUNDAY);
	push_enum(result, "monday",    UCAL_MONDAY);
	push_enum(result, "tuesday",   UCAL_TUESDAY);
	push_enum(result, "wednesday", UCAL_WEDNESDAY);
	push_enum(result, "thursday",  UCAL_THURSDAY);
	push_enum(result, "friday",    UCAL_FRIDAY);
	push_enum(result, "saturday",  UCAL_SATURDAY);
	return result;
}

static VALUE
icu_calendar_display_name_type_enum(VALUE module)
{
	VALUE result = rb_ary_new2(4);
	push_enum(result, "dst",            UCAL_DST);
	push_enum(result, "short_dst",      UCAL_SHORT_DST);
	push_enum(result, "short_standard", UCAL_SHORT_STANDARD);
	push_enum(result, "standard",       UCAL_STANDARD);
	return result;
}

static VALUE
icu_calendar_limit_type_enum(VALUE module)
{
	VALUE result = rb_ary_new2(6);
	push_enum(result, "minimum",          UCAL_MINIMUM);
	push_enum(result, "maximum",          UCAL_MAXIMUM);
	push_enum(result, "greatest_minimum", UCAL_GREATEST_MINIMUM);
	push_enum(result, "least_maximum",    UCAL_LEAST_MAXIMUM);
	push_enum(result, "actual_minimum",   UCAL_ACTUAL_MINIMUM);
	push_enum(result, "actual_maximum",   UCAL_ACTUAL_MAXIMUM);
	return result;
}

static VALUE
icu_calendar_locale_type_enum(VALUE module)
{
	VALUE result = rb_ary_new2(2);
	push_enum(result, "actual", ULOC_ACTUAL_LOCALE);
	push_enum(result, "valid",  ULOC_VALID_LOCALE);
	return result;
}

static VALUE
icu_calendar_month_enum(VALUE module)
{
	VALUE result = rb_ary_new2(13);
	push_enum(result, "january",    UCAL_JANUARY);
	push_enum(result, "february",   UCAL_FEBRUARY);
	push_enum(result, "march",      UCAL_MARCH);
	push_enum(result, "april",      UCAL_APRIL);
	push_enum(result, "may",        UCAL_MAY);
	push_enum(result, "june",       UCAL_JUNE);
	push_enum(result, "july",       UCAL_JULY);
	push_enum(result, "august",     UCAL_AUGUST);
	push_enum(result, "september",  UCAL_SEPTEMBER);
	push_enum(result, "october",    UCAL_OCTOBER);
	push_enum(result, "november",   UCAL_NOVEMBER);
	push_enum(result, "december",   UCAL_DECEMBER);
	push_enum(result, "undecimber", UCAL_UNDECIMBER);
	return result;
}

static VALUE
icu_calendar_system_timezone_type_enum(VALUE module)
{
	VALUE result = rb_ary_new2(3);
#if U_ICU_VERSION_MAJOR_NUM > 4 || (U_ICU_VERSION_MAJOR_NUM == 4 && U_ICU_VERSION_MINOR_NUM >= 8)
	push_enum(result, "any",                UCAL_ZONE_TYPE_ANY);
	push_enum(result, "canonical",          UCAL_ZONE_TYPE_CANONICAL);
	push_enum(result, "canonical_location", UCAL_ZONE_TYPE_CANONICAL_LOCATION);
#endif
	return result;
}

static VALUE
icu_calendar_timezone_transition_type_enum(VALUE module)
{
	VALUE result = rb_ary_new2(4);
#if U_ICU_VERSION_MAJOR_NUM >= 50
	push_enum(result, "next",               UCAL_TZ_TRANSITION_NEXT);
	push_enum(result, "next_inclusive",     UCAL_TZ_TRANSITION_NEXT_INCLUSIVE);
	push_enum(result, "previous",           UCAL_TZ_TRANSITION_PREVIOUS);
	push_enum(result, "previous_inclusive", UCAL_TZ_TRANSITION_PREVIOUS_INCLUSIVE);
#endif
	return result;
}

static VALUE
icu_calendar_walltime_option_enum(VALUE module)
{
	VALUE result = rb_ary_new2(3);
#if U_ICU_VERSION_MAJOR_NUM >= 49
	push_enum(result, "last",       UCAL_WALLTIME_LAST);
	push_enum(result, "first",      UCAL_WALLTIME_FIRST);
	push_enum(result, "next_valid", UCAL_WALLTIME_NEXT_VALID);
#endif
	return result;
}

static VALUE
icu_calendar_weekday_type_enum(VALUE module)
{
	VALUE result = rb_ary_new2(4);
#if U_ICU_VERSION_MAJOR_NUM > 4 || (U_ICU_VERSION_MAJOR_NUM == 4 && U_ICU_VERSION_MINOR_NUM >= 4)
	push_enum(result, "weekday",       UCAL_WEEKDAY);
	push_enum(result, "weekend",       UCAL_WEEKEND);
	push_enum(result, "weekend_onset", UCAL_WEEKEND_ONSET);
	push_enum(result, "weekend_cease", UCAL_WEEKEND_CEASE);
#endif
	return result;
}

void Init_icu_constants()
{
	VALUE rb_mICU, rb_cICUCalendar, rb_mICUCalendarLibrary;

	rb_mICU = rb_define_module("ICU");
	rb_cICUCalendar = rb_define_class_under(rb_mICU, "Calendar", rb_cObject);
	rb_mICUCalendarLibrary = rb_define_module_under(rb_cICUCalendar, "Library");

	rb_define_class_under(rb_cICUCalendar, "RuntimeError", rb_eRuntimeError);

	rb_define_const(rb_mICUCalendarLibrary, "U_BUFFER_OVERFLOW_ERROR", INT2NUM(U_BUFFER_OVERFLOW_ERROR));
	rb_define_const(rb_mICUCalendarLibrary, "U_ICU_VERSION", rb_str_new(U_ICU_VERSION, strlen(U_ICU_VERSION)));
	rb_define_const(rb_mICUCalendarLibrary, "U_MAX_VERSION_LENGTH", INT2NUM(U_MAX_VERSION_LENGTH));
	rb_define_const(rb_mICUCalendarLibrary, "U_MAX_VERSION_STRING_LENGTH", INT2NUM(U_MAX_VERSION_STRING_LENGTH));
	rb_define_const(rb_mICUCalendarLibrary, "U_ZERO_ERROR", INT2NUM(U_ZERO_ERROR));

	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "am_pm_enum", icu_calendar_am_pm_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "attribute_enum", icu_calendar_attribute_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "calendar_type_enum", icu_calendar_calendar_type_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "date_field_enum", icu_calendar_date_field_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "day_of_week_enum", icu_calendar_day_of_week_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "display_name_type_enum", icu_calendar_display_name_type_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "limit_type_enum", icu_calendar_limit_type_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "locale_type_enum", icu_calendar_locale_type_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "month_enum", icu_calendar_month_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "system_timezone_type_enum", icu_calendar_system_timezone_type_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "timezone_transition_type_enum", icu_calendar_timezone_transition_type_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "walltime_option_enum", icu_calendar_walltime_option_enum, 0);
	rb_define_private_method(rb_singleton_class(rb_mICUCalendarLibrary), "weekday_type_enum", icu_calendar_weekday_type_enum, 0);
}
