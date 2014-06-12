require 'icu/calendar/library'

module ICU
  class Calendar
    include Comparable

    class << self
      def available_locales
        (0...Library.ucal_countAvailable).map { |i| Library.ucal_getAvailable(i) }
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
      result = Library.assert_success do |status|
        Library.ucal_get(@calendar, field, status)
      end

      case field
      when :am_pm, :day_of_week, :month
        Library.enum_type(field)[result]
      else
        result
      end
    end

    def []=(field, value)
      if value.nil?
        Library.ucal_clearField(@calendar, field)
      else
        Library.ucal_set(@calendar, field, value)
      end
    end

    def <=>(other)
      if Calendar === other
        time <=> other.time
      else
        time <=> coerce_to_milliseconds(other)
      end
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

    def initialize(timezone = nil, locale = nil)
      calendar = wchar_buffer_from_string_or_nil(timezone) do |timezone|
        Library.assert_success do |status|
          Library.ucal_open(timezone, -1, locale, :default, status)
        end
      end

      @calendar = automatically_close(calendar)
    end

    def is_set?(field)
      Library.ucal_isSet(@calendar, field)
    end

    def locale(type = :valid)
      Library.assert_success do |status|
        Library.ucal_getLocaleByType(@calendar, type, status)
      end
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

    protected

    attr_accessor :calendar

    private

    def automatically_close(calendar_pointer)
      FFI::AutoPointer.new(calendar_pointer, Library.method(:ucal_close))
    end

    def coerce_to_milliseconds(value)
      value = value.to_time if value.respond_to? :to_time
      value = value.dup.utc.to_f * 1000 if value.is_a? Time
      value
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
