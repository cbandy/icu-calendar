class ICU::Calendar
  module Library
    class ErrorCode < FFI::MemoryPointer
      extend FFI::DataConverter

      def self.native_type
        FFI::Type::POINTER
      end

      def initialize
        super(:int)
      end

      def buffer_overflow?
        to_i == U_BUFFER_OVERFLOW_ERROR
      end

      def failure?
        to_i > U_ZERO_ERROR
      end

      def success?
        to_i <= U_ZERO_ERROR
      end

      alias_method :to_i, :read_int

      def to_s
        Library.u_errorName(to_i)
      end
    end
  end
end
