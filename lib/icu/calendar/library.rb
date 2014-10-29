require 'ffi'
require_relative 'icu_constants'
require_relative 'library/error_code'
require_relative 'library/version_info'

module ICU
  class Calendar
    module Library
      extend FFI::Library

      ffi_lib('libicutu').each do |library|
        @suffix ||= ['', '_4_2', '_44', '_46', *(48..100).map { |i| "_#{i}" }].find do |suffix|
          function_names("u_errorName#{suffix}", nil).any? { |name| library.find_function(name) }
        end
      end

      class << self
        def assert_success
          ErrorCode.new do |status|
            result = yield status
            raise RuntimeError, status.to_s unless status.success?
            return result
          end
        end

        def read_into_wchar_buffer(length)
          ErrorCode.new do |status|
            for attempts in 1..2
              FFI::Buffer.new(:uint16, length, false) do |buffer|
                length = yield buffer, status
                return buffer.read_array_of_uint16(length).pack('U*') if status.success?
                raise RuntimeError, status.to_s unless status.buffer_overflow?
                status.clear
              end
            end
            raise RuntimeError, "#{status}: Needed #{length}"
          end
        end

        def read_wchar_enumeration(open)
          return enum_for(:read_wchar_enumeration, open) unless block_given?

          Library::ErrorCode.new do |status|
            enumeration = open.call(status)
            raise RuntimeError, status.to_s unless status.success?

            begin
              FFI::MemoryPointer.new(:int32) do |length|
                loop do
                  pointer = Library.uenum_unext(enumeration, length, status)
                  raise RuntimeError, status.to_s unless status.success?
                  break if pointer.null?
                  yield pointer.read_array_of_uint16(length.read_int32).pack('U*')
                end
              end
            ensure
              Library.uenum_close(enumeration)
            end
          end
        end

        def version
          @version ||= VersionInfo.new.tap { |version| u_getVersion(version) }
        end

        def wchar_buffer_from_string(string, &block)
          codepoints = string.encode('UTF-8').unpack('U*') << 0
          FFI::Buffer.new(:uint16, codepoints.length, false) do |buffer|
            buffer.write_array_of_uint16(codepoints)
            return yield buffer
          end
        end

        private

        def attach_icu_function(name, type, *args)
          attach_function name, "#{name}#{@suffix}", *args, type
        end

        def icu_version_at_least(version)
          Gem::Version.new(version) <= Gem::Version.new(self.version)
        end
      end

      enum :am_pm,                    am_pm_enum
      enum :attribute,                attribute_enum
      enum :calendar_type,            calendar_type_enum
      enum :date_field,               date_field_enum
      enum :day_of_week,              day_of_week_enum
      enum :display_name_type,        display_name_type_enum
      enum :limit_type,               limit_type_enum
      enum :locale_type,              locale_type_enum
      enum :month,                    month_enum
      enum :system_timezone_type,     system_timezone_type_enum
      enum :timezone_transition_type, timezone_transition_type_enum
      enum :walltime_option,          walltime_option_enum
      enum :weekday_type,             weekday_type_enum

      typedef :pointer,    :calendar
      typedef :double,     :date
      typedef :pointer,    :enumeration
      typedef ErrorCode,   :status
      typedef VersionInfo, :version

      attach_icu_function :u_errorName, :string, [:int]

      attach_icu_function :u_getVersion,      :void, [:version]
      attach_icu_function :u_versionToString, :void, [:version, :buffer_out]

      # Enumeration
      attach_icu_function :uenum_close, :void,    [:enumeration]
      attach_icu_function :uenum_next,  :string,  [:enumeration, :buffer_out, :status]
      attach_icu_function :uenum_unext, :pointer, [:enumeration, :buffer_out, :status]

      # Locales
      attach_icu_function :ucal_countAvailable, :int32,  []
      attach_icu_function :ucal_getAvailable,   :string, [:int32]
      attach_icu_function :uloc_getDefault,     :string, []

      # Time Zones
      attach_icu_function :ucal_getCanonicalTimeZoneID, :int32,  [:buffer_in, :int32, :buffer_out, :int32, :buffer_out, :status]
      attach_icu_function :ucal_getDefaultTimeZone,     :int32,  [:buffer_out, :int32, :status]
      attach_icu_function :ucal_getDSTSavings,          :int32,  [:buffer_in, :status]
      attach_icu_function :ucal_getTZDataVersion,       :string, [:status]
      attach_icu_function :ucal_setDefaultTimeZone,     :void,   [:buffer_in, :status]

      attach_icu_function :ucal_openTimeZones,          :enumeration, [:status]
      attach_icu_function :ucal_openCountryTimeZones,   :enumeration, [:string, :status]

      # Calendar
      attach_icu_function :ucal_clone,        :calendar, [:calendar, :status]
      attach_icu_function :ucal_close,        :void,     [:calendar]
      attach_icu_function :ucal_equivalentTo, :bool,     [:calendar, :calendar]
      attach_icu_function :ucal_open,         :calendar, [:buffer_in, :int32, :string, :calendar_type, :status]

      attach_icu_function :ucal_getAttribute,           :int32,  [:calendar, :attribute]
      attach_icu_function :ucal_getGregorianChange,     :date,   [:calendar, :status]
      attach_icu_function :ucal_getLocaleByType,        :string, [:calendar, :locale_type, :status]
      attach_icu_function :ucal_getMillis,              :date,   [:calendar, :status]
      attach_icu_function :ucal_getTimeZoneDisplayName, :int32,  [:calendar, :display_name_type, :string, :buffer_out, :int32, :status]
      attach_icu_function :ucal_getType,                :string, [:calendar, :status]
      attach_icu_function :ucal_inDaylightTime,         :bool,   [:calendar, :status]
      attach_icu_function :ucal_setAttribute,           :void,   [:calendar, :attribute, :int32]
      attach_icu_function :ucal_setDate,                :void,   [:calendar, :int32, :month, :int32, :status]
      attach_icu_function :ucal_setDateTime,            :void,   [:calendar, :int32, :month, :int32, :int32, :int32, :int32, :status]
      attach_icu_function :ucal_setGregorianChange,     :void,   [:calendar, :date, :status]
      attach_icu_function :ucal_setMillis,              :void,   [:calendar, :date, :status]
      attach_icu_function :ucal_setTimeZone,            :void,   [:calendar, :buffer_in, :int32, :status]

      # Calendar Fields
      attach_icu_function :ucal_add,        :void,  [:calendar, :date_field, :int32, :status]
      attach_icu_function :ucal_clear,      :void,  [:calendar]
      attach_icu_function :ucal_clearField, :void,  [:calendar, :date_field]
      attach_icu_function :ucal_get,        :int32, [:calendar, :date_field, :status]
      attach_icu_function :ucal_getLimit,   :int32, [:calendar, :date_field, :limit_type, :status]
      attach_icu_function :ucal_isSet,      :bool,  [:calendar, :date_field]
      attach_icu_function :ucal_roll,       :void,  [:calendar, :date_field, :int32, :status]
      attach_icu_function :ucal_set,        :void,  [:calendar, :date_field, :int32]

      if icu_version_at_least('4.4')
        attach_icu_function :ucal_getDayOfWeekType,     :weekday_type, [:calendar, :day_of_week, :status]
        attach_icu_function :ucal_getWeekendTransition, :int32,        [:calendar, :day_of_week, :status]
        attach_icu_function :ucal_isWeekend,            :bool,         [:calendar, :date, :status]
      end

      if icu_version_at_least('4.8')
        attach_icu_function :ucal_getFieldDifference,        :int32,       [:calendar, :date, :date_field, :status]
        attach_icu_function :ucal_openTimeZoneIDEnumeration, :enumeration, [:system_timezone_type, :string, :buffer_in, :status]
      end

      if icu_version_at_least('50')
        attach_icu_function :ucal_getTimeZoneTransitionDate, :bool, [:calendar, :timezone_transition_type, :buffer_out, :status]
      end

      if icu_version_at_least('51')
        attach_icu_function :ucal_getTimeZoneID, :int32, [:calendar, :buffer_out, :int32, :status]
      end
    end
  end
end
