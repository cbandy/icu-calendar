# encoding: UTF-8

require 'icu/calendar'

module ICU
  describe Calendar do
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

      describe 'offset timezones' do
        it 'returns a list of timezones for an offset in milliseconds' do
          expect(Calendar.offset_timezones(-10_800_000)).to include('BET')
          expect(Calendar.offset_timezones(3_600_000)).to include('Europe/Berlin')
        end
      end
    end
  end
end
