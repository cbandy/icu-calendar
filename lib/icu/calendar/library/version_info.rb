class ICU::Calendar
  module Library
    class VersionInfo < FFI::MemoryPointer
      extend FFI::DataConverter

      def self.native_type
        FFI::Type::POINTER
      end

      def initialize
        super(:uint8, U_MAX_VERSION_LENGTH)
      end

      def to_a
        read_array_of_uint8(U_MAX_VERSION_LENGTH)
      end

      def to_s
        buffer = FFI::MemoryPointer.new(:char, U_MAX_VERSION_STRING_LENGTH);
        Library.u_versionToString(self, buffer)
        buffer.read_string_to_null
      end
    end
  end
end
