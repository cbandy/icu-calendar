require 'icu/calendar'

describe ICU::Calendar do
  Calendar = ICU::Calendar

  def self.icu_version_at_least(version)
    Gem::Version.new(version) <= Gem::Version.new(Calendar::Library.version)
  end

  def icu_version_at_least(version)
    self.class.icu_version_at_least(version)
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
        expect(Calendar.country_timezones('DE')).to include('Europe/Berlin')
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

    describe 'default timezone' do
      subject(:default) { Calendar.default_timezone }

      let(:timezone) do
        timezones = Calendar.timezones
        timezones.delete(Calendar.default_timezone)
        timezones.sample
      end

      before { @original = Calendar.default_timezone }
      after  { Calendar.default_timezone = @original }

      it 'is a UTF-8 String' do
        expect(default).to be_a String
        expect(default.encoding).to be(Encoding::UTF_8)
      end

      it 'can be assigned' do
        expect(Calendar.default_timezone = timezone).to eq(timezone)
        expect(Calendar.default_timezone).to eq(timezone)
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
        expect(Calendar.timezone_identifiers(:canonical, 'DE')).to include('Europe/Berlin')
      end

      it 'filters timezones by offset in milliseconds' do
        expect(Calendar.timezone_identifiers(:any, nil, -10_800_000)).to include('BET')
        expect(Calendar.timezone_identifiers(:canonical, nil, 3_600_000)).to include('Europe/Berlin')
      end
    end
  end

  describe 'initialization' do
    context 'with no arguments' do
      subject(:calendar) { Calendar.new }

      it 'uses the default locale' do
        expect(calendar.locale).to eq(Calendar::Library.uloc_getDefault)
      end

      it 'uses the default timezone' do
        if icu_version_at_least('51')
          expect(calendar.timezone).to eq(Calendar.default_timezone)
        end
      end
    end

    context 'with a nil timezone' do
      subject(:calendar) { Calendar.new(nil) }

      it 'uses the default timezone' do
        if icu_version_at_least('51')
          expect(calendar.timezone).to eq(Calendar.default_timezone)
        end
      end
    end

    context 'with a timezone' do
      subject(:calendar) { Calendar.new(timezone) }
      let(:timezone) do
        timezones = Calendar.timezones
        timezones.delete(Calendar.default_timezone)
        timezones.sample
      end

      it 'uses that timezone' do
        if icu_version_at_least('51')
          expect(calendar.timezone).to eq(timezone)
        end
      end
    end

    context 'with a nil locale' do
      subject(:calendar) { Calendar.new('UTC', nil) }

      it 'uses the default locale' do
        expect(calendar.locale).to eq(Calendar::Library.uloc_getDefault)
      end
    end

    context 'with a locale' do
      subject(:calendar) { Calendar.new(nil, 'de_DE') }

      it 'uses that locale' do
        expect(calendar.locale).to eq('de_DE')
      end
    end
  end

  describe '#daylight_time?' do
    subject(:calendar) { Calendar.new('US/Central') }

    specify do
      calendar.time = Time.new(2010, 5, 8)
      expect(calendar).to be_daylight_time
    end

    specify do
      calendar.time = Time.new(2012, 11, 15)
      expect(calendar).to_not be_daylight_time
    end
  end

  describe '#locale' do
    it 'returns the locale' do
      expect(Calendar.new(nil, 'en_US').locale).to eq('en_US')

      if icu_version_at_least('4.6')
        expect(Calendar.new(nil, 'de').locale).to eq('de_DE')
      else
        expect(Calendar.new(nil, 'de').locale).to eq('de')
      end
    end

    it 'returns the locale in which the calendar rules are defined' do
      if icu_version_at_least('4.8')
        expect(Calendar.new(nil, 'en_US').locale(:actual)).to eq('en')
        expect(Calendar.new(nil, 'zh_TW').locale(:actual)).to eq('zh_Hant')
      else
        expect(Calendar.new(nil, 'en_US').locale(:actual)).to eq('en_US')
        expect(Calendar.new(nil, 'zh_TW').locale(:actual)).to eq('zh_Hant_TW')
      end
    end
  end

  describe '#time' do
    subject(:calendar) { Calendar.new }

    it 'is the number of milliseconds since 1970-01-01 00:00:00 UTC' do
      expect(calendar.time).to be_within(1000).of(Time.now.utc.to_f * 1000)
      expect(calendar.time).to be_a Float
    end

    describe 'assignment' do
      let(:datetime) { DateTime.iso8601(:'2012-11-15T00:04:01Z') }
      let(:integer)  { 1352937841_000 }
      let(:time)     { Time.utc(2012, 11, 15, 0, 4, 1) }

      it 'can be assigned with an Integer' do
        expect(calendar.time = integer).to be(integer)
        expect(calendar.time).to eq(integer)
        expect(calendar.time).to be_a Float
      end

      it 'can be assigned with a Time' do
        expect(calendar.time = time).to be(time)
        expect(calendar.time).to eq(integer)
        expect(calendar.time).to be_a Float
      end

      it 'does not modify the passed Time' do
        expect { calendar.time = time }.to_not change { time.utc? }
      end

      it 'can be assigned with a DateTime' do
        require 'date'
        expect(calendar.time = datetime).to be(datetime)
        expect(calendar.time).to eq(integer)
        expect(calendar.time).to be_a Float
      end
    end
  end

  describe '#timezone', if: icu_version_at_least('51') do
    subject(:calendar) { Calendar.new }
    let(:timezone) do
      timezones = Calendar.timezones
      timezones.delete(Calendar.default_timezone)
      timezones.sample
    end

    it 'can be assigned' do
      expect(calendar.timezone = timezone).to eq(timezone)
      expect(calendar.timezone).to eq(timezone)
    end

    context 'when assigned nil' do
      subject(:calendar) { Calendar.new(timezone) }

      it 'uses the default locale' do
        expect(calendar.timezone = nil).to be_nil
        expect(calendar.timezone).to eq(Calendar.default_timezone)
      end
    end
  end
end
