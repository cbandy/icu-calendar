# encoding: UTF-8

require 'icu/calendar'

module ICU
  describe Calendar do
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
    end
  end
end
