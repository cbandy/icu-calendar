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

  describe '#[]' do
    subject(:calendar) { Calendar.new }

    it 'gets the requested field of the assigned time' do
      calendar.time = Time.local(2012, 11, 15, 0, 4, 1)

      expect(calendar[:year]).to eq(2012)
      expect(calendar[:month]).to eq(:november)
      expect(calendar[:day_of_month]).to eq(15)
      expect(calendar[:day_of_week]).to eq(:thursday)
      expect(calendar[:hour]).to eq(0)
      expect(calendar[:minute]).to eq(4)
      expect(calendar[:second]).to eq(1)
      expect(calendar[:am_pm]).to eq(:am)
    end

    it 'returns raw values when called with an Integer' do
      date_field_enum = Calendar::Library.enum_type(:date_field)
      calendar.time = Time.local(2012, 11, 15, 0, 4, 1)

      expect(calendar[date_field_enum[:month]]).to eq(10)
      expect(calendar[date_field_enum[:day_of_week]]).to eq(5)
      expect(calendar[date_field_enum[:am_pm]]).to eq(0)
    end
  end

  describe '#[]=' do
    subject(:calendar) { Calendar.new }

    it 'sets the requested field of the assigned time' do
      calendar.time = Time.local(2012, 11, 15, 0, 4, 1)

      calendar[:year] = 2013; expect(calendar).to eq(Time.local(2013, 11, 15, 0, 4, 1))
      calendar[:month] = :october; expect(calendar).to eq(Time.local(2013, 10, 15, 0, 4, 1))
      calendar[:hour] = 13; expect(calendar).to eq(Time.local(2013, 10, 15, 13, 4, 1))
    end
  end

  describe '#<=>' do
    subject(:calendar) { Calendar.new }
    before { calendar.time = Time.local(2012, 11, 15, 0, 4, 1) }

    context 'with a Time' do
      specify { expect(calendar <=> Time.local(2012, 11, 15, 0, 4, 2)).to eq(-1) }
      specify { expect(calendar <=> Time.local(2012, 11, 15, 0, 4, 1)).to eq(0) }
      specify { expect(calendar <=> Time.local(2012, 11, 15, 0, 4, 0)).to eq(1) }
    end

    context 'with a Calendar' do
      let(:other) { Calendar.new }

      specify { other.time = Time.local(2012, 11, 15, 0, 4, 2); expect(calendar <=> other).to eq(-1) }
      specify { other.time = Time.local(2012, 11, 15, 0, 4, 1); expect(calendar <=> other).to eq(0) }
      specify { other.time = Time.local(2012, 11, 15, 0, 4, 0); expect(calendar <=> other).to eq(1) }
    end

    it 'is Comparable' do
      expect(calendar).to be_a Comparable
    end
  end

  describe '#add' do
    subject(:calendar) { Calendar.new }
    before { calendar.time = Time.local(2012, 11, 15, 0, 4, 1) }

    context 'with a positive value' do
      it 'moves the time of the calendar forward' do
        expect(calendar.add(:year, 1)).to eq(Time.local(2013, 11, 15, 0, 4, 1))
        expect(calendar.add(:month, 2)).to eq(Time.local(2014, 1, 15, 0, 4, 1))
        expect(calendar.add(:am_pm, 1)).to eq(Time.local(2014, 1, 15, 12, 4, 1))
      end
    end

    context 'with a negative value' do
      it 'moves the time of the calendar backward' do
        expect(calendar.add(:year, -1)).to eq(Time.local(2011, 11, 15, 0, 4, 1))
        expect(calendar.add(:day_of_month, -4)).to eq(Time.local(2011, 11, 11, 0, 4, 1))
        expect(calendar.add(:hour, -2)).to eq(Time.local(2011, 11, 10, 22, 4, 1))
      end
    end

    context 'with zero' do
      it 'does not change the calendar' do
        [:year, :month, :day_of_month, :hour, :am_pm].each do |field|
          expect { calendar.add(field, 0) }.to_not change { calendar }
          expect { calendar.add(field, 0) }.to_not change { calendar.time }
        end
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

  describe '#dup' do
    let(:original) { Calendar.new }
    subject(:copy) { original.dup }

    it 'creates a copy' do
      expect(copy).to eql(original)
      expect(copy).to_not be(original)
    end
  end

  describe '#eql?' do
    subject(:calendar) { Calendar.new }
    let(:other) { Calendar.new }
    let(:time)  { Time.now }

    it 'compares the behavior of two Calendars and their time' do
      calendar.time = time
      other.time = time

      expect(calendar).to eql(other)
    end

    it 'returns false when the Calendars have different times' do
      calendar.time = time
      other.time = time + 1

      expect(calendar).to_not eql(other)
    end

    it 'returns false when the Calendars are not equivalent' do
      other.first_day_of_week = :wednesday
      expect(calendar).to_not eql(other)
    end

    it 'returns false for values other than Calendar' do
      expect(calendar).to_not eql(:symbol)
      expect(calendar).to_not eql(Time.new)
    end
  end

  describe '#equivalent?' do
    subject(:calendar) { Calendar.new }
    let(:other)        { Calendar.new }
    let(:timezone) do
      timezones = Calendar.timezones
      timezones.delete(Calendar.default_timezone)
      timezones.sample
    end

    it 'compares the behavior of two Calendars' do
      expect(calendar).to be_equivalent(calendar)
      expect(calendar).to be_equivalent(other)
    end

    it 'does not compare the time of two Calendars' do
      other.time = Time.new(2000, 1, 1)

      expect(calendar.time).to_not eq(other.time)
      expect(calendar).to be_equivalent(other)
    end

    it 'returns false when the timezones differ' do
      other.timezone = timezone
      expect(calendar).to_not be_equivalent(other)
    end

    it 'returns false when the attributes differ' do
      other.first_day_of_week = :wednesday
      expect(calendar).to_not be_equivalent(other)
    end

    it 'returns false for values other than Calendar' do
      expect(calendar).to_not be_equivalent(:symbol)
      expect(calendar).to_not be_equivalent(Time.new)
    end
  end

  describe '#first_day_of_week' do
    subject(:calendar) { Calendar.new(nil, 'en_US') }

    it 'returns a Day of Week' do
      expect(calendar.first_day_of_week).to be(:sunday)
    end

    it 'can be assigned using a Day of Week' do
      expect(calendar.first_day_of_week = :monday).to be(:monday)
      expect(calendar.first_day_of_week).to be(:monday)
    end

    it 'can be assigned using an Integer' do
      expect(calendar.first_day_of_week = 5).to be(5)
      expect(calendar.first_day_of_week).to be(:thursday)
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

  describe '#roll' do
    subject(:calendar) { Calendar.new }
    before { calendar.time = Time.local(2012, 11, 15, 0, 4, 1) }

    context 'with a positive value' do
      it 'moves the field forward in time' do
        expect(calendar.roll(:year, 1)).to eq(Time.local(2013, 11, 15, 0, 4, 1))
        expect(calendar.roll(:month, 2)).to eq(Time.local(2013, 1, 15, 0, 4, 1))
        expect(calendar.roll(:am_pm, 1)).to eq(Time.local(2013, 1, 15, 12, 4, 1))
      end
    end

    context 'with a negative value' do
      it 'moves the field backward in time' do
        expect(calendar.roll(:year, -1)).to eq(Time.local(2011, 11, 15, 0, 4, 1))
        expect(calendar.roll(:day_of_month, -4)).to eq(Time.local(2011, 11, 11, 0, 4, 1))
        expect(calendar.roll(:hour, -2)).to eq(Time.local(2011, 11, 11, 10, 4, 1))
      end
    end

    context 'with zero' do
      it 'does not change the calendar' do
        [:year, :month, :day_of_month, :hour, :am_pm].each do |field|
          expect { calendar.roll(field, 0) }.to_not change { calendar }
          expect { calendar.roll(field, 0) }.to_not change { calendar.time }
        end
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
