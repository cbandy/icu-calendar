require 'icu/calendar/library'

describe ICU::Calendar::Library::VersionInfo do
  subject(:version) { described_class.new.write_array_of_uint8([8,2,6,1]) }

  it 'can be treated as an array of integers' do
    expect(version.to_a).to eq([8,2,6,1])
  end

  it 'can be treated as a string' do
    expect(version.to_s).to eq('8.2.6.1')
  end
end
