# encoding: UTF-8

require 'icu/calendar'

module ICU
  describe Calendar do
    it 'defines a RuntimeError' do
      Calendar::RuntimeError.new.should be_a ::RuntimeError
    end

    describe 'available locales' do
      subject { Calendar.available_locales }

      it { should be_an Array }
      it { should_not be_empty }
      its(:first) { should be_a String }
    end

    describe 'timezones' do
      subject { Calendar.timezones }

      it { should be_an Array }
      it { should_not be_empty }
      its(:first) { should be_a String }
      its(:'first.encoding') { should == Encoding::UTF_8 }

      describe 'canonical timezone identifier' do
        it 'returns a canonical system identifier' do
          Calendar.canonical_timezone_identifier('GMT').should == 'Etc/GMT'
        end

        it 'returns a normalized custom identifier' do
          Calendar.canonical_timezone_identifier('GMT-6').should == 'GMT-06:00'
          Calendar.canonical_timezone_identifier('GMT+1:15').should == 'GMT+01:15'
        end
      end

      describe 'country timezones' do
        it 'returns a list of timezones associated with a country' do
          Calendar.country_timezones('DE').should == ['Europe/Berlin']
          Calendar.country_timezones('US').should include 'America/Chicago'
          Calendar.country_timezones('CN').should_not include 'UTC'
        end

        it 'returns a list of timezones associated with no countries' do
          Calendar.country_timezones(nil).should include 'UTC'
        end
      end

      describe 'offset timezones' do
        it 'returns a list of timezones for an offset in milliseconds' do
          Calendar.offset_timezones(-10_800_000).should include 'BET'
          Calendar.offset_timezones(3_600_000).should include 'Europe/Berlin'
        end
      end
    end
  end
end
