require 'icu/calendar'

describe ICU::Calendar::Library do

  shared_examples 'an enumeration' do |name, values|
    subject(:enum) { ICU::Calendar::Library.enum_type(name) }

    it { should be_an FFI::Enum }
    specify { expect(enum.to_hash).to eq(values) }
    specify { expect(ICU::Calendar::Library.find_type(name)).to be }
  end

  describe 'Loaded ICU version' do
    subject(:version) { ICU::Calendar::Library.version }

    it { should be_a ICU::Calendar::Library::VersionInfo }
    specify { expect(version.to_a).to be_all { |part| part.is_a? Integer } }
    specify { expect(version.to_s).to match /^[0-9.]+$/ }
  end

  describe 'Asserting a successful status' do
    it 'yields an ErrorCode' do
      yielded = false

      ICU::Calendar::Library.assert_success do |status|
        yielded = true
        expect(status).to be_a ICU::Calendar::Library::ErrorCode
        expect(status).to be_success
      end

      expect(yielded).to be true
    end

    context 'when the status contains success' do
      it 'returns the result of the passed block' do
        result = double
        expect(ICU::Calendar::Library.assert_success { result }).to be(result)
      end
    end

    context 'when the status contains failure' do
      it 'raises a RuntimeError' do
        expect {
          ICU::Calendar::Library.assert_success { |status| status.write_int(5) }
        }.to raise_error(ICU::Calendar::RuntimeError)
      end
    end
  end

  describe 'Reading from a UChar buffer' do
    let(:length) { 1 }

    it 'yields a buffer and an ErrorCode' do
      yielded = false

      ICU::Calendar::Library.read_into_wchar_buffer(length) do |buffer, status|
        yielded = true
        expect(buffer).to be_an FFI::AbstractMemory
        expect(buffer.size).to be(buffer.type_size * length)
        expect(status).to be_a ICU::Calendar::Library::ErrorCode
        length
      end

      expect(yielded).to be true
    end

    context 'when the status contains success' do
      it 'reads from the buffer contents' do
        result = ICU::Calendar::Library.read_into_wchar_buffer(length) do |buffer, status|
          buffer.write_uint16('A'.ord)
          length
        end

        expect(result).to eq('A')
      end

      it 'returns a UTF-8 String' do
        result = ICU::Calendar::Library.read_into_wchar_buffer(length) do |buffer, status|
          buffer.write_uint16(376)
          length
        end

        expect(result).to eq("\u0178")
        expect(result.encoding).to be(Encoding::UTF_8)
      end
    end

    context 'when the status contains overflow' do
      let(:overflow_error) { ICU::Calendar::Library::U_BUFFER_OVERFLOW_ERROR }

      it 'yields again with a new buffer and cleared status' do
        invocations = 0
        original_buffer = nil
        original_length = 1
        yielded_length = 2

        ICU::Calendar::Library.read_into_wchar_buffer(original_length) do |buffer, status|
          case invocations += 1
          when 1
            original_buffer = buffer
            status.write_int(overflow_error)
          when 2
            expect(buffer).to_not be(original_buffer)
            expect(buffer.size).to be(buffer.type_size * yielded_length)
            expect(status).to be_success
          end
          yielded_length
        end

        expect(invocations).to be(2)
      end

      it 'yields only twice' do
        invocations = 0

        expect {
          ICU::Calendar::Library.read_into_wchar_buffer(length) do |_, status|
            invocations += 1
            status.write_int(overflow_error)
            length
          end
        }.to raise_error ICU::Calendar::RuntimeError

        expect(invocations).to be(2)
      end
    end

    context 'when the status is an error other than overflow' do
      let(:error) { 5 }

      it 'raises a RuntimeError immediately' do
        invocations = 0

        expect {
          ICU::Calendar::Library.read_into_wchar_buffer(length) do |_, status|
            invocations += 1
            status.write_int(error)
          end
        }.to raise_error ICU::Calendar::RuntimeError

        expect(invocations).to be(1)
      end
    end
  end

  describe 'Creating a UChar buffer from a String' do
    let(:utf8) { "RUB\xC5\xB8".force_encoding('UTF-8') }
    let(:windows1252) { "RUB\x9F".force_encoding('Windows-1252') }

    it 'yields a null-terminated buffer' do
      ICU::Calendar::Library.wchar_buffer_from_string('') do |buffer|
        expect(buffer).to be_an FFI::AbstractMemory
        expect(buffer.get_uint16(buffer.size - buffer.type_size)).to be(0)
      end
    end

    it 'converts a Ruby String to UChar' do
      ICU::Calendar::Library.wchar_buffer_from_string(utf8) do |buffer|
        expect(buffer.read_array_of_uint16(buffer.size / buffer.type_size)).to eq([82, 85, 66, 376, 0])
      end

      ICU::Calendar::Library.wchar_buffer_from_string(windows1252) do |buffer|
        expect(buffer.read_array_of_uint16(buffer.size / buffer.type_size)).to eq([82, 85, 66, 376, 0])
      end
    end

    it 'returns the result of the passed block' do
      result = double
      expect(ICU::Calendar::Library.wchar_buffer_from_string('') { result }).to be(result)
    end
  end

  describe 'Reading a UEnumeration' do
    context 'without a block' do
      it 'returns an Enumerable' do
        expect(ICU::Calendar::Library.read_wchar_enumeration(double)).to be_an Enumerable
      end
    end

    let(:opener) { double(call: nil) }
    let(:null)   { double(null?: true) }

    before do
      allow(ICU::Calendar::Library).to receive(:uenum_unext).and_return(null)
      allow(ICU::Calendar::Library).to receive(:uenum_close)
    end

    it 'calls the Proc with an ErrorCode' do
      expect(opener).to receive(:call) do |status|
        expect(status).to be_a ICU::Calendar::Library::ErrorCode
        expect(status).to be_success
      end

      ICU::Calendar::Library.read_wchar_enumeration(opener) {}
    end

    context 'when the Proc status is not success' do
      let(:opener) { lambda { |status| status.write_int(5) } }

      it 'raises a RuntimeError' do
        expect { ICU::Calendar::Library.read_wchar_enumeration(opener) {} }.to raise_error ICU::Calendar::RuntimeError
      end
    end

    context 'when the enumeration is opened successfully' do
      let(:enumeration) { double }
      let(:opener) { double(call: enumeration) }

      it 'closes the enumeration' do
        expect(ICU::Calendar::Library).to receive(:uenum_close).with(enumeration)
        ICU::Calendar::Library.read_wchar_enumeration(opener) {}
      end

      it 'calls uenum_unext' do
        expect(ICU::Calendar::Library).to receive(:uenum_unext) do |arg1, arg2, arg3|
          expect(arg1).to be(enumeration)
          expect(arg2).to be_an FFI::AbstractMemory
          expect(arg3).to be_a ICU::Calendar::Library::ErrorCode
          expect(arg3).to be_success
          null
        end

        ICU::Calendar::Library.read_wchar_enumeration(opener) {}
      end

      context 'when uenum_unext fails' do
        before { allow(ICU::Calendar::Library).to receive(:uenum_unext) { |_, _, status| status.write_int(5) } }

        it 'raises a RuntimeError' do
          expect { ICU::Calendar::Library.read_wchar_enumeration(opener) {} }.to raise_error ICU::Calendar::RuntimeError
        end

        it 'closes the enumeration' do
          expect(ICU::Calendar::Library).to receive(:uenum_close).with(enumeration)
          ICU::Calendar::Library.read_wchar_enumeration(opener) {} rescue nil
        end
      end

      context 'when uenum_unext succeeds' do
        let(:length)  { double(read_int32: 0) }
        let(:pointer) { double(null?: false, read_array_of_uint16: [82, 85, 66, 376]) }

        it 'yields next UTF-8 string in the enumeration' do
          expect(ICU::Calendar::Library).to receive(:uenum_unext).ordered.and_return(pointer)
          expect(ICU::Calendar::Library).to receive(:uenum_unext).ordered.and_return(null)

          ICU::Calendar::Library.read_wchar_enumeration(opener) do |result|
            expect(result).to eq("RUB\u0178")
            expect(result.encoding).to be(Encoding::UTF_8)
          end
        end
      end
    end
  end

  describe 'Default Locale' do
    subject(:default) { ICU::Calendar::Library.uloc_getDefault }

    it { should be_a String }
  end

  describe 'AM/PM' do
    it_behaves_like 'an enumeration', :am_pm,
      am: 0, pm: 1
  end

  describe 'Attribute' do
    it_behaves_like 'an enumeration', :attribute,
      lenient: 0, first_day_of_week: 1, minimal_days_in_first_week: 2, repeated_wall_time: 3, skipped_wall_time: 4
  end

  describe 'Calendar Type' do
    it_behaves_like 'an enumeration', :calendar_type,
      default: 0, gregorian: 1
  end

  describe 'Date Field' do
    it_behaves_like 'an enumeration', :date_field,
      era: 0, year: 1, month: 2, week_of_year: 3, week_of_month: 4, date: 5, day_of_year: 6, day_of_month: 5, day_of_week: 7, day_of_week_in_month: 8,
      am_pm: 9, hour: 10, hour_of_day: 11, minute: 12, second: 13, millisecond: 14, zone_offset: 15, dst_offset: 16,
      year_woy: 17, dow_local: 18, extended_year: 19, julian_day: 20, milliseconds_in_day: 21, is_leap_month: 22, field_count: 23
  end

  describe 'Day of Week' do
    it_behaves_like 'an enumeration', :day_of_week,
      sunday: 1, monday: 2, tuesday: 3, wednesday: 4, thursday: 5, friday: 6, saturday: 7
  end

  describe 'Display Name Type' do
    it_behaves_like 'an enumeration', :display_name_type,
      standard: 0, short_standard: 1, dst: 2, short_dst: 3
  end

  describe 'Limit Type' do
    it_behaves_like 'an enumeration', :limit_type,
      minimum: 0, maximum: 1, greatest_minimum: 2, least_maximum: 3, actual_minimum: 4, actual_maximum: 5
  end

  describe 'Locale Type' do
    it_behaves_like 'an enumeration', :locale_type,
      actual: 0, valid: 1
  end

  describe 'Month' do
    it_behaves_like 'an enumeration', :month,
      january: 0, february: 1, march: 2, april: 3, may: 4, june: 5, july: 6, august: 7, september: 8, october: 9, november: 10, december: 11, undecimber: 12
  end

  describe 'System Time Zone Type' do
    it_behaves_like 'an enumeration', :system_timezone_type,
      any: 0, canonical: 1, canonical_location: 2
  end

  describe 'Time Zone Transition Type' do
    it_behaves_like 'an enumeration', :timezone_transition_type,
      next: 0, next_inclusive: 1, previous: 2, previous_inclusive: 3
  end

  describe 'Wall Time Option' do
    it_behaves_like 'an enumeration', :walltime_option,
      last: 0, first: 1, next_valid: 2
  end

  describe 'Weekday Type' do
    it_behaves_like 'an enumeration', :weekday_type,
      weekday: 0, weekend: 1, weekend_onset: 2, weekend_cease: 3
  end
end
