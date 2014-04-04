require 'icu/calendar/library'

module ICU
  class Calendar
    class << self
      def available_locales
        (0...Library.ucal_countAvailable).map { |i| Library.ucal_getAvailable(i) }
      end

      def canonical_timezone_identifier(timezone)
        FFI::MemoryPointer.new(:bool) do |is_system_id|
          Library.wchar_buffer_from_string(timezone) do |timezone|
            return Library.read_into_wchar_buffer(32) do |buffer, status|
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
        Library::ErrorCode.new do |status|
          Library.wchar_buffer_from_string(timezone) do |timezone|
            Library.ucal_setDefaultTimeZone(timezone, status)
            raise RuntimeError, status.to_s unless status.success?
          end
        end
      end

      def dst_savings(timezone)
        Library::ErrorCode.new do |status|
          Library.wchar_buffer_from_string(timezone) do |timezone|
            result = Library.ucal_getDSTSavings(timezone, status)
            raise RuntimeError, status.to_s unless status.success?
            return result
          end
        end
      end

      def timezone_data_version
        Library::ErrorCode.new do |status|
          result = Library.ucal_getTZDataVersion(status)
          raise RuntimeError, status.to_s unless status.success?
          return result
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
  end
end
