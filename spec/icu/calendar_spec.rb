require 'icu/calendar'

describe ICU::Calendar do
  Calendar = ICU::Calendar

  def self.icu_version_at_least(version)
    Gem::Version.new(version) <= Gem::Version.new(Calendar::Library.version)
  end

  it 'defines a RuntimeError' do
    expect(Calendar::RuntimeError.new).to be_a(::RuntimeError)
  end

  describe 'available locales' do
    subject(:locales) { Calendar.available_locales }

    it { should be_an Array }
    it { should_not be_empty }

    it 'contains Strings' do
      expect(locales.first).to be_a(String)
    end
  end

  describe 'timezones' do
    subject(:zones) { Calendar.timezones }

    it { should be_an Array }
    it { should_not be_empty }

    it 'contains UTF-8 Strings' do
      expect(zones.first).to be_a(String)
      expect(zones.first.encoding).to be(Encoding::UTF_8)
    end

    describe 'canonical timezone identifier' do
      it 'returns a canonical system identifier' do
        expect(Calendar.canonical_timezone_identifier('GMT')).to eq('Etc/GMT')
      end

      it 'returns a normalized custom identifier' do
        expect(Calendar.canonical_timezone_identifier('GMT-6')).to eq('GMT-06:00')
        expect(Calendar.canonical_timezone_identifier('GMT+1:15')).to eq('GMT+01:15')
      end
    end

    describe 'country timezones' do
      it 'returns a list of timezones associated with a country' do
        expect(Calendar.country_timezones('DE')).to eq(['Europe/Berlin'])
        expect(Calendar.country_timezones('US')).to include('America/Chicago')
        expect(Calendar.country_timezones('CN')).to_not include('UTC')
      end

      it 'returns a list of timezones associated with no countries' do
        expect(Calendar.country_timezones(nil)).to include('UTC')
      end
    end

    describe 'daylight savings' do
      it 'returns the milliseconds added during daylight savings time' do
        expect(Calendar.dst_savings('America/Chicago')).to be(3_600_000)
        expect(Calendar.dst_savings('GMT')).to be(0)
      end
    end

    describe 'timezone data version' do
      subject { Calendar.timezone_data_version }
      it { should be_a String }
    end

    describe 'timezone identifiers', if: icu_version_at_least('4.8') do
      it 'returns timezones of a particular type' do
        expect(Calendar.timezone_identifiers(:any)).to include('UTC')
        expect(Calendar.timezone_identifiers(:canonical)).to include('Factory')
        expect(Calendar.timezone_identifiers(:canonical_location)).to include('America/Chicago')
      end

      it 'filters timezones by country' do
        expect(Calendar.timezone_identifiers(:any, 'US')).to_not include('UTC')
        expect(Calendar.timezone_identifiers(:canonical, 'DE')).to eq(['Europe/Berlin'])
      end

      it 'filters timezones by offset in milliseconds' do
        expect(Calendar.timezone_identifiers(:any, nil, -10_800_000)).to include('BET')
        expect(Calendar.timezone_identifiers(:canonical, nil, 3_600_000)).to include('Europe/Berlin')
      end
    end
  end
end
