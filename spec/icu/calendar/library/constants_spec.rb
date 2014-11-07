require 'icu/calendar/library'
require 'support/compiling'

icu_headers =
  begin
    Compiling.execute(<<-CODE)
#include <stdio.h>
#include "unicode/uversion.h"
main() { printf("%s", U_ICU_VERSION); }
CODE
  rescue
    false
  end

describe ICU::Calendar::Library, icu_headers: icu_headers, if: icu_headers do

  def self.icu_headers_at_least(version)
    metadata[:icu_headers] && Gem::Version.new(version) <= Gem::Version.new(metadata[:icu_headers])
  end

  shared_examples 'the original enumeration' do |name, prefix, suffix = ''|
    let(:enum) { ICU::Calendar::Library.enum_type(name) }
    let(:symbols) { enum.symbols }

    specify do
      expect(Compiling.execute(<<-CODE)).to eq symbols.map { |s| enum[s] }.join("\n") << "\n"
#include <stdio.h>
#include "unicode/ucal.h"
#include "unicode/uloc.h"
main() { #{ symbols.each_with_object('') { |symbol, out| out << %( printf("%d\\n", #{prefix}#{symbol.upcase}#{suffix}); ) } } }
      CODE
    end
  end

  specify do
    expect(Compiling.execute(<<-'CODE')).to eq <<-EXPECTED
#include <stdio.h>
#include "unicode/utypes.h"
main () {
  printf("%d\n", U_BUFFER_OVERFLOW_ERROR);
  printf("%d\n", U_MAX_VERSION_LENGTH);
  printf("%d\n", U_MAX_VERSION_STRING_LENGTH);
  printf("%d\n", U_ZERO_ERROR);
}
    CODE
#{ICU::Calendar::Library::U_BUFFER_OVERFLOW_ERROR}
#{ICU::Calendar::Library::U_MAX_VERSION_LENGTH}
#{ICU::Calendar::Library::U_MAX_VERSION_STRING_LENGTH}
#{ICU::Calendar::Library::U_ZERO_ERROR}
    EXPECTED
  end

  describe 'AM/PM' do
    it_behaves_like 'the original enumeration', :am_pm, :'UCAL_'
  end

  describe 'Attribute' do
    if icu_headers_at_least('49')
      it_behaves_like 'the original enumeration', :attribute, :'UCAL_'
    else
      let(:enum) { ICU::Calendar::Library.enum_type(:attribute) }
      let(:symbols) { %w(lenient first_day_of_week minimal_days_in_first_week).map(&:to_sym) }

      specify do
        expect(Compiling.execute(<<-'CODE')).to eq symbols.map { |s| enum[s] }.join("\n") << "\n"
#include <stdio.h>
#include "unicode/ucal.h"
main() {
  printf("%d\n", UCAL_LENIENT);
  printf("%d\n", UCAL_FIRST_DAY_OF_WEEK);
  printf("%d\n", UCAL_MINIMAL_DAYS_IN_FIRST_WEEK);
}
        CODE
      end
    end
  end

  describe 'Calendar Type' do
    it_behaves_like 'the original enumeration', :calendar_type, :'UCAL_'
  end

  describe 'Date Field' do
    it_behaves_like 'the original enumeration', :date_field, :'UCAL_'
  end

  describe 'Day of Week' do
    it_behaves_like 'the original enumeration', :day_of_week, :'UCAL_'
  end

  describe 'Display Name Type' do
    it_behaves_like 'the original enumeration', :display_name_type, :'UCAL_'
  end

  describe 'Limit Type' do
    it_behaves_like 'the original enumeration', :limit_type, :'UCAL_'
  end

  describe 'Locale Type' do
    it_behaves_like 'the original enumeration', :locale_type, :'ULOC_', :'_LOCALE'
  end

  describe 'Month' do
    it_behaves_like 'the original enumeration', :month, :'UCAL_'
  end

  describe 'System Time Zone Type', if: icu_headers_at_least('4.8') do
    it_behaves_like 'the original enumeration', :system_timezone_type, :'UCAL_ZONE_TYPE_'
  end

  describe 'Time Zone Transition Type', if: icu_headers_at_least('50') do
    it_behaves_like 'the original enumeration', :timezone_transition_type, :'UCAL_TZ_TRANSITION_'
  end

  describe 'Wall Time Option', if: icu_headers_at_least('49') do
    it_behaves_like 'the original enumeration', :walltime_option, :'UCAL_WALLTIME_'
  end

  describe 'Weekday Type', if: icu_headers_at_least('4.4') do
    it_behaves_like 'the original enumeration', :weekday_type, :'UCAL_'
  end
end
