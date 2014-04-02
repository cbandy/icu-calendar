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
        result = []

        Library::ErrorCode.new do |status|
          enumeration = Library.ucal_openCountryTimeZones(country, status)
          raise RuntimeError, status.to_s unless status.success?

          begin
            FFI::MemoryPointer.new(:int32) do |length|
              until (pointer = Library.uenum_unext(enumeration, length, status)).null?
                raise RuntimeError, status.to_s unless status.success?
                result << pointer.read_array_of_uint16(length.read_int32).pack('U*')
              end
            end
          ensure
            Library.uenum_close(enumeration)
          end
        end

        result
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
        result = []

        Library::ErrorCode.new do |status|
          offset = FFI::MemoryPointer.new(:int32).write_int32(offset) unless offset.nil?
          begin
            enumeration = Library.ucal_openTimeZoneIDEnumeration(type, region, offset, status)
            raise RuntimeError, status.to_s unless status.success?

            begin
              FFI::MemoryPointer.new(:int32) do |length|
                until (pointer = Library.uenum_unext(enumeration, length, status)).null?
                  raise RuntimeError, status.to_s unless status.success?
                  result << pointer.read_array_of_uint16(length.read_int32).pack('U*')
                end
              end
            ensure
              Library.uenum_close(enumeration)
            end
          ensure
            offset.free unless offset.nil?
          end
        end

        result
      end

      def timezones
        result = []

        Library::ErrorCode.new do |status|
          enumeration = Library.ucal_openTimeZones(status)
          raise RuntimeError, status.to_s unless status.success?

          begin
            FFI::MemoryPointer.new(:int32) do |length|
              until (pointer = Library.uenum_unext(enumeration, length, status)).null?
                raise RuntimeError, status.to_s unless status.success?
                result << pointer.read_array_of_uint16(length.read_int32).pack('U*')
              end
            end
          ensure
            Library.uenum_close(enumeration)
          end
        end

        result
      end

    end
  end
end
