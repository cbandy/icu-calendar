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
    end
  end
end
