module Groupdate
  module Adapters
    class RedshiftAdapter < BaseAdapter
      def group_clause
        time_zone = @time_zone.tzinfo.name
        day_start_column = "CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL ?"
        day_start_interval = "#{day_start} second"

        query =
          case period
          when :minute_of_hour
            ["EXTRACT(MINUTE FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :hour_of_day
            ["EXTRACT(HOUR FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :day_of_week
            ["EXTRACT(DOW FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :day_of_month
            ["EXTRACT(DAY FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :day_of_year
            ["EXTRACT(DOY FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :month_of_year
            ["EXTRACT(MONTH FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :week # start on Sunday, not Redshift default Monday
            # Redshift does not return timezone information; it
            # always says it is in UTC time, so we must convert
            # back to UTC to play properly with the rest of Groupdate.
            week_start_interval = "#{week_start} day"
            ["CONVERT_TIMEZONE(?, 'Etc/UTC', DATE_TRUNC('week', #{day_start_column} - INTERVAL ?) + INTERVAL ? + INTERVAL ?)::timestamp", time_zone, time_zone, day_start_interval, week_start_interval, week_start_interval, day_start_interval]
          when :custom
            ["TIMESTAMP 'epoch' + (FLOOR(EXTRACT(EPOCH FROM #{column}::timestamp) / ?) * ?) * INTERVAL '1 second'", n_seconds, n_seconds]
          else
            ["CONVERT_TIMEZONE(?, 'Etc/UTC', DATE_TRUNC(?, #{day_start_column}) + INTERVAL ?)::timestamp", time_zone, period, time_zone, day_start_interval, day_start_interval]
          end

        @relation.send(:sanitize_sql_array, query)
      end
    end
  end
end
