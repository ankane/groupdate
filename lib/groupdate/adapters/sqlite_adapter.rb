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

        if !@time_zone.utc_offset.zero? || !day_start.zero? || period == :quarter
          setup_function
          day_start = self.day_start != 0 ? self.day_start / 3600.0 : nil
          week_start = period == :week ? Groupdate::Magic::DAYS[self.week_start].to_s : nil
          query = ["groupdate(?, #{column}, ?, ?, ?)", period, @time_zone.tzinfo.name, day_start, week_start]
        end

        @relation.send(:sanitize_sql_array, query)
      end

      private

      def setup_function
        @relation.connection_pool.with_connection do |connection|
          raw_connection = connection.raw_connection
          return if raw_connection.instance_variable_defined?(:@groupdate_function)

          utc = ActiveSupport::TimeZone["UTC"]
          # TODO improve performance
          raw_connection.create_function("groupdate", 4) do |func, period, value, time_zone, day_start, week_start|
            if value.nil?
              func.result = nil
            else
              options = {time_zone: time_zone}
              options[:day_start] = day_start if day_start
              options[:week_start] = week_start if week_start
              result = [value].group_by_period(period, **options) { |v| utc.parse(v) }.keys[0]
              if result.is_a?(Time)
                result = result.in_time_zone(utc).strftime("%Y-%m-%d %H:%M:%S")
              elsif result.is_a?(Date)
                result = result.strftime("%Y-%m-%d")
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
