class ICU::Calendar
  module Library

    class << self
      private

      def am_pm_enum
        [:am, :pm]
      end

      def attribute_enum
        [
          :lenient, :first_day_of_week, :minimal_days_in_first_week,
          # ICU >= 49
          :repeated_wall_time, :skipped_wall_time,
        ]
      end

      def calendar_type_enum
        [:default, :gregorian]
      end

      def date_field_enum
        [
          :era, :year, :month, :week_of_year, :week_of_month,
          :date, :day_of_year, :day_of_month, 5, :day_of_week, 7, :day_of_week_in_month,
          :am_pm, :hour, :hour_of_day, :minute, :second, :millisecond, :zone_offset, :dst_offset,
          :year_woy, :dow_local, :extended_year, :julian_day, :milliseconds_in_day, :is_leap_month,
          :field_count
        ]
      end

      def day_of_week_enum
        [:sunday, 1, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]
      end

      def display_name_type_enum
        [:standard, :short_standard, :dst, :short_dst]
      end

      def limit_type_enum
        [:minimum, :maximum, :greatest_minimum, :least_maximum, :actual_minimum, :actual_maximum]
      end

      def locale_type_enum
        [:actual, :valid]
      end

      def month_enum
        [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december, :undecimber]
      end

      def system_timezone_type_enum
        [:any, :canonical, :canonical_location]
      end

      def timezone_transition_type_enum
        [:next, :next_inclusive, :previous, :previous_inclusive]
      end

      def walltime_option_enum
        [:last, :first, :next_valid]
      end

      def weekday_type_enum
        [:weekday, :weekend, :weekend_onset, :weekend_cease]
      end
    end

  end
end
