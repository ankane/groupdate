module Groupdate
  module Adapters
    class PostgreSQLAdapter < BaseAdapter
      def group_clause
        time_zone = @time_zone.tzinfo.name
        day_start_column = "#{column}::timestamptz AT TIME ZONE ? - INTERVAL ?"
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
          when :week
            ["(DATE_TRUNC('day', #{day_start_column} - INTERVAL '1 day' * ((? + EXTRACT(DOW FROM #{day_start_column})::integer) % 7)) + INTERVAL ?) AT TIME ZONE ?", time_zone, day_start_interval, 13 - week_start, time_zone, day_start_interval, day_start_interval, time_zone]
          when :custom
            ["TO_TIMESTAMP(FLOOR(EXTRACT(EPOCH FROM #{column}::timestamptz) / ?) * ?)", n_seconds, n_seconds]
          else
            if day_start == 0
              # prettier
              ["DATE_TRUNC(?, #{day_start_column}) AT TIME ZONE ?", period, time_zone, day_start_interval, time_zone]
            else
              ["(DATE_TRUNC(?, #{day_start_column}) + INTERVAL ?) AT TIME ZONE ?", period, time_zone, day_start_interval, day_start_interval, time_zone]
            end
          end

        clean_group_clause(@relation.send(:sanitize_sql_array, query))
      end

      def clean_group_clause(clause)
        clause.gsub(/ (\-|\+) INTERVAL '0 second'/, "")
      end
    end
  end
end
