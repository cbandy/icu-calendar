require 'icu/calendar/library'

module ICU
  class Calendar
    include Comparable

    class << self
      def available_locales
        (0...Library.ucal_countAvailable).map(&Library.method(:ucal_getAvailable))
      end

      def canonical_timezone_identifier(timezone)
        FFI::MemoryPointer.new(:bool) do |is_system_id|
          return Library.wchar_buffer_from_string(timezone) do |timezone|
            Library.read_into_wchar_buffer(32) do |buffer, status|
              Library.ucal_getCanonicalTimeZoneID(
                timezone, -1,
                buffer, buffer.size / buffer.type_size,
                is_system_id, status
              )
            end
          end
        end
      end

      def country_timezones(country)
        Library.read_wchar_enumeration(->(status) do
          Library.ucal_openCountryTimeZones(country, status)
        end).to_a
      end

      def default_timezone
        Library.read_into_wchar_buffer(32) do |buffer, status|
          Library.ucal_getDefaultTimeZone(buffer, buffer.size / buffer.type_size, status)
        end
      end

      def default_timezone=(timezone)
        Library.wchar_buffer_from_string(timezone) do |timezone|
          Library.assert_success do |status|
            Library.ucal_setDefaultTimeZone(timezone, status)
          end
        end
      end

      def dst_savings(timezone)
        Library.wchar_buffer_from_string(timezone) do |timezone|
          Library.assert_success do |status|
            Library.ucal_getDSTSavings(timezone, status)
          end
        end
      end

      def timezone_data_version
        Library.assert_success do |status|
          Library.ucal_getTZDataVersion(status)
        end
      end

      def timezone_identifiers(type, region = nil, offset = nil)
        offset = FFI::MemoryPointer.new(:int32).write_int32(offset) unless offset.nil?

        Library.read_wchar_enumeration(->(status) do
          Library.ucal_openTimeZoneIDEnumeration(type, region, offset, status)
        end).to_a
      ensure
        offset.free unless offset.nil?
      end

      def timezones
        Library.read_wchar_enumeration(->(status) do
          Library.ucal_openTimeZones(status)
        end).to_a
      end
    end

    def [](field)
      field_value_to_symbol(field, Library.assert_success do |status|
        Library.ucal_get(@calendar, field, status)
      end)
    end

    def []=(field, value)
      if value.nil?
        Library.ucal_clearField(@calendar, field)
      else
        Library.ucal_set(@calendar, field, value)
      end
    end

    def <=>(other)
      time <=> coerce_to_milliseconds(other)
    end

    def actual_maximum(field)
      field_value_to_symbol(field, Library.assert_success do |status|
        Library.ucal_getLimit(@calendar, field, :actual_maximum, status)
      end)
    end

    def actual_minimum(field)
      field_value_to_symbol(field, Library.assert_success do |status|
        Library.ucal_getLimit(@calendar, field, :actual_minimum, status)
      end)
    end

    def add(field, amount)
      Library.assert_success do |status|
        Library.ucal_add(@calendar, field, amount, status)
      end

      self
    end

    def clear
      Library.ucal_clear(@calendar)
    end

    def daylight_time?
      Library.assert_success do |status|
        Library.ucal_inDaylightTime(@calendar, status)
      end
    end

    def difference(from, field)
      from = coerce_to_milliseconds(from)
      Library.assert_success do |status|
        Library.ucal_getFieldDifference(@calendar, from, field, status)
      end
    end

    def dup
      calendar = automatically_close(
        Library.assert_success do |status|
          Library.ucal_clone(@calendar, status)
        end
      )

      result = self.class.allocate
      result.calendar = calendar
      result
    end

    def eql?(other)
      equivalent?(other) && time == other.time
    end

    def equivalent?(other)
      Calendar === other && Library.ucal_equivalentTo(@calendar, other.calendar)
    end

    def first_day_of_week
      Library.enum_type(:day_of_week)[Library.ucal_getAttribute(@calendar, :first_day_of_week)]
    end

    def first_day_of_week=(day_of_week)
      day_of_week = Library.enum_type(:day_of_week)[day_of_week] if Symbol === day_of_week
      Library.ucal_setAttribute(@calendar, :first_day_of_week, day_of_week)
    end

    def greatest_minimum(field)
      field_value_to_symbol(field, Library.assert_success do |status|
        Library.ucal_getLimit(@calendar, field, :greatest_minimum, status)
      end)
    end

    def initialize(options = {})
      calendar = wchar_buffer_from_string_or_nil(options[:timezone]) do |timezone|
        Library.assert_success do |status|
          Library.ucal_open(timezone, -1, options[:locale], :default, status)
        end
      end

      @calendar = automatically_close(calendar)
    end

    def is_set?(field)
      Library.ucal_isSet(@calendar, field)
    end

    def least_maximum(field)
      field_value_to_symbol(field, Library.assert_success do |status|
        Library.ucal_getLimit(@calendar, field, :least_maximum, status)
      end)
    end

    def lenient?
      Library.ucal_getAttribute(@calendar, :lenient).nonzero?
    end

    def lenient=(value)
      Library.ucal_setAttribute(@calendar, :lenient, value ? 1 : 0)
    end

    def locale(type = :valid)
      Library.assert_success do |status|
        Library.ucal_getLocaleByType(@calendar, type, status)
      end
    end

    def maximum(field)
      field_value_to_symbol(field, Library.assert_success do |status|
        Library.ucal_getLimit(@calendar, field, :maximum, status)
      end)
    end

    def minimal_days_in_first_week
      Library.ucal_getAttribute(@calendar, :minimal_days_in_first_week)
    end

    def minimal_days_in_first_week=(value)
      Library.ucal_setAttribute(@calendar, :minimal_days_in_first_week, value)
    end

    def minimum(field)
      field_value_to_symbol(field, Library.assert_success do |status|
        Library.ucal_getLimit(@calendar, field, :minimum, status)
      end)
    end

    def next_timezone_transition(inclusive = false)
      timezone_transition(inclusive ? :next_inclusive : :next)
    end

    def previous_timezone_transition(inclusive = false)
      timezone_transition(inclusive ? :previous_inclusive : :previous)
    end

    def repeated_wall_time
      Library.enum_type(:walltime_option)[Library.ucal_getAttribute(@calendar, :repeated_wall_time)]
    end

    def repeated_wall_time=(option)
      option = Library.enum_type(:walltime_option)[option] if Symbol === option
      Library.ucal_setAttribute(@calendar, :repeated_wall_time, option)
    end

    def roll(field, amount)
      Library.assert_success do |status|
        Library.ucal_roll(@calendar, field, amount, status)
      end

      self
    end

    def set_date(year, month, day)
      Library.assert_success do |status|
        Library.ucal_setDate(@calendar, year, month, day, status)
      end
    end

    def set_date_and_time(year, month, day, hour, minute, second)
      Library.assert_success do |status|
        Library.ucal_setDateTime(@calendar, year, month, day, hour, minute, second, status)
      end
    end

    def skipped_wall_time
      Library.enum_type(:walltime_option)[Library.ucal_getAttribute(@calendar, :skipped_wall_time)]
    end

    def skipped_wall_time=(option)
      option = Library.enum_type(:walltime_option)[option] if Symbol === option
      Library.ucal_setAttribute(@calendar, :skipped_wall_time, option)
    end

    def time
      Library.assert_success do |status|
        Library.ucal_getMillis(@calendar, status)
      end
    end

    def time=(time)
      time = coerce_to_milliseconds(time)

      Library.assert_success do |status|
        Library.ucal_setMillis(@calendar, time, status)
      end
    end

    def timezone
      Library.read_into_wchar_buffer(32) do |buffer, status|
        Library.ucal_getTimeZoneID(@calendar, buffer, buffer.size / buffer.type_size, status)
      end
    end

    def timezone=(timezone)
      wchar_buffer_from_string_or_nil(timezone) do |timezone|
        Library.assert_success do |status|
          Library.ucal_setTimeZone(@calendar, timezone, -1, status)
        end
      end
    end

    def type
      Library.assert_success do |status|
        Library.ucal_getType(@calendar, status)
      end.to_sym
    end

    def weekday_type(day_of_week)
      Library.assert_success do |status|
        Library.ucal_getDayOfWeekType(@calendar, day_of_week, status)
      end
    end

    def weekend?
      Library.assert_success do |status|
        Library.ucal_isWeekend(@calendar, time, status)
      end
    end

    def weekend_transition(day_of_week)
      Library.assert_success do |status|
        Library.ucal_getWeekendTransition(@calendar, day_of_week, status)
      end
    end

    protected

    attr_accessor :calendar

    private

    def automatically_close(calendar_pointer)
      FFI::AutoPointer.new(calendar_pointer, Library.method(:ucal_close))
    end

    def coerce_to_milliseconds(value)
      if Calendar === value
        value.time
      else
        value = value.to_time if value.respond_to? :to_time
        value = value.getutc.to_f * 1000 if value.is_a? Time
        value
      end
    end

    def field_value_to_symbol(field, value)
      case field
      when :am_pm, :day_of_week, :month
        Library.enum_type(field)[value]
      else
        value
      end
    end

    def timezone_transition(type)
      FFI::MemoryPointer.new(:double) do |time|
        valid = Library.assert_success do |status|
          Library.ucal_getTimeZoneTransitionDate(@calendar, type, time, status)
        end

        return valid ? time.read_double : nil
      end
    end

    def wchar_buffer_from_string_or_nil(string)
      if string.nil?
        yield string
      else
        Library.wchar_buffer_from_string(string) do |buffer|
          yield buffer
        end
      end
    end
  end
end
