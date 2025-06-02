module Groupdate
  module Adapters
    class SQLiteAdapter < BaseAdapter
      def group_clause
        query =
          if period == :week
            ["strftime('%Y-%m-%d', #{column}, '-6 days', ?)", "weekday #{(week_start + 1) % 7}"]
          elsif period == :custom
            ["datetime((strftime('%s', #{column}) / ?) * ?, 'unixepoch')", n_seconds, n_seconds]
          else
            format =
              case period
              when :minute_of_hour
                "%M"
              when :hour_of_day
                "%H"
              when :day_of_week
                "%w"
              when :day_of_month
                "%d"
              when :day_of_year
                "%j"
              when :month_of_year
                "%m"
              when :second
                "%Y-%m-%d %H:%M:%S UTC"
              when :minute
                "%Y-%m-%d %H:%M:00 UTC"
              when :hour
                "%Y-%m-%d %H:00:00 UTC"
              when :day
                "%Y-%m-%d"
              when :month
                "%Y-%m-01"
              when :quarter
                nil
              else # year
                "%Y-01-01"
              end

            ["strftime(?, #{column})", format]
          end

        if period != :custom && (@time_zone != SeriesBuilder.utc || day_start != 0 || period == :quarter)
          setup_function
          week_start = period == :week ? Groupdate::Magic::DAYS[self.week_start].to_s : nil
          query = ["groupdate_internal(?, #{column}, ?, ?, ?)", period, @time_zone.tzinfo.name, day_start, week_start]
        end

        @relation.send(:sanitize_sql_array, query)
      end

      private

      def setup_function
        @relation.connection_pool.with_connection do |connection|
          raw_connection = connection.raw_connection
          return if raw_connection.instance_variable_defined?(:@groupdate_function)

          utc = SeriesBuilder.utc
          date_periods = %i[day week month quarter year]

          # note: this function is part of the internal API and may change between releases
          # TODO improve performance
          raw_connection.create_function("groupdate_internal", 4) do |func, period, value, time_zone, day_start, week_start|
            if value.nil?
              func.result = nil
            else
              period = period.to_sym
              # cast_result handles week_start for day_of_week
              week_start = :sunday if period == :day_of_week
              result = SeriesBuilder.round_time(utc.parse(value), period, ActiveSupport::TimeZone[time_zone], day_start.to_i, week_start&.to_sym)
              if date_periods.include?(period)
                result = result.strftime("%Y-%m-%d")
              elsif result.is_a?(Time)
                result = result.in_time_zone(utc).strftime("%Y-%m-%d %H:%M:%S")
              end
              func.result = result
            end
          end
          raw_connection.instance_variable_set(:@groupdate_function, true)
        end
      end
    end
  end
end
