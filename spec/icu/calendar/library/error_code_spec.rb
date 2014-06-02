require 'icu/calendar/library'

describe ICU::Calendar::Library::ErrorCode do
  it 'is initialized to zero error' do
    expect(subject.to_i).to be(ICU::Calendar::Library::U_ZERO_ERROR)
  end

  describe '#buffer_overflow?' do
    specify { expect(subject.write_int( 0)).to_not be_buffer_overflow }
    specify { expect(subject.write_int(15)).to be_buffer_overflow }
  end

  describe '#success?' do
    specify { expect(subject.write_int( 0)).to be_success }
    specify { expect(subject.write_int(-1)).to be_success }
    specify { expect(subject.write_int(15)).to_not be_success }
  end

  describe '#failure?' do
    specify { expect(subject.write_int( 0)).to_not be_failure }
    specify { expect(subject.write_int(-1)).to_not be_failure }
    specify { expect(subject.write_int(15)).to be_failure }
  end

  it 'can be treated as a string' do
    expect(subject.to_s).to eq('U_ZERO_ERROR')
    expect(subject.write_int(15).to_s).to eq('U_BUFFER_OVERFLOW_ERROR')
    expect(subject.write_int(16).to_s).to eq('U_UNSUPPORTED_ERROR')
  end
end
