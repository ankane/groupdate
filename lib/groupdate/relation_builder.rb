module Groupdate
  class RelationBuilder
    attr_reader :period, :column, :day_start, :week_start

    def initialize(relation, column:, period:, time_zone:, time_range:, week_start:, day_start:)
      @relation = relation
      @column = resolve_column(relation, column)
      @period = period
      @time_zone = time_zone
      @time_range = time_range
      @week_start = week_start
      @day_start = day_start

      if relation.default_timezone == :local
        raise Groupdate::Error, "ActiveRecord::Base.default_timezone must be :utc to use Groupdate"
      end
    end

    def generate
      @relation.group(group_clause).where(*where_clause)
    end

    private

    def group_clause
      time_zone = @time_zone.tzinfo.name
      adapter_name = @relation.connection.adapter_name
      query =
        case adapter_name
        when "Mysql2", "Mysql2Spatial", "Mysql2Rgeo"
          case period
          when :minute_of_hour
            ["MINUTE(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second)", time_zone, day_start]
          when :hour_of_day
            ["HOUR(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second)", time_zone, day_start]
          when :day_of_week
            ["DAYOFWEEK(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second) - 1", time_zone, day_start]
          when :day_of_month
            ["DAYOFMONTH(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second)", time_zone, day_start]
          when :day_of_year
            ["DAYOFYEAR(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second)", time_zone, day_start]
          when :month_of_year
            ["MONTH(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second)", time_zone, day_start]
          when :week
            ["CONVERT_TZ(DATE_FORMAT(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second - INTERVAL ((? + WEEKDAY(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second)) % 7) DAY, '%Y-%m-%d 00:00:00') + INTERVAL ? second, ?, '+00:00')", time_zone, day_start, 7 - week_start, time_zone, day_start, day_start, time_zone]
          when :quarter
            ["CONVERT_TZ(DATE_FORMAT(DATE(CONCAT(EXTRACT(YEAR FROM CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second), '-', LPAD(1 + 3 * (QUARTER(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second) - 1), 2, '00'), '-01')), '%Y-%m-%d %H:%i:%S') + INTERVAL ? second, ?, '+00:00')", time_zone, day_start, time_zone, day_start, day_start, time_zone]
          else
            format =
              case period
              when :second
                "%Y-%m-%d %H:%i:%S"
              when :minute
                "%Y-%m-%d %H:%i:00"
              when :hour
                "%Y-%m-%d %H:00:00"
              when :day
                "%Y-%m-%d 00:00:00"
              when :month
                "%Y-%m-01 00:00:00"
              else # year
                "%Y-01-01 00:00:00"
              end

            ["CONVERT_TZ(DATE_FORMAT(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second, ?) + INTERVAL ? second, ?, '+00:00')", time_zone, day_start, format, day_start, time_zone]
          end
        when "PostgreSQL", "PostGIS"
          day_start_interval = "#{day_start} second"

          case period
          when :minute_of_hour
            ["EXTRACT(MINUTE FROM #{column}::timestamptz AT TIME ZONE ? - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :hour_of_day
            ["EXTRACT(HOUR FROM #{column}::timestamptz AT TIME ZONE ? - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :day_of_week
            ["EXTRACT(DOW FROM #{column}::timestamptz AT TIME ZONE ? - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :day_of_month
            ["EXTRACT(DAY FROM #{column}::timestamptz AT TIME ZONE ? - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :day_of_year
            ["EXTRACT(DOY FROM #{column}::timestamptz AT TIME ZONE ? - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :month_of_year
            ["EXTRACT(MONTH FROM #{column}::timestamptz AT TIME ZONE ? - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :week # start on Sunday, not PostgreSQL default Monday
            # TODO just subtract number of days from day of week like MySQL?
            week_start_interval = "#{week_start} day"
            ["(DATE_TRUNC('week', #{column}::timestamptz AT TIME ZONE ? - INTERVAL ? - INTERVAL ?) + INTERVAL ? + INTERVAL ?) AT TIME ZONE ?", time_zone, day_start_interval, week_start_interval, week_start_interval, day_start_interval, time_zone]
          else
            if day_start == 0
              # prettier
              ["DATE_TRUNC(?, #{column}::timestamptz AT TIME ZONE ?) AT TIME ZONE ?", period, time_zone, time_zone]
            else
              ["(DATE_TRUNC(?, #{column}::timestamptz AT TIME ZONE ? - INTERVAL ?) + INTERVAL ?) AT TIME ZONE ?", period, time_zone, day_start_interval, day_start_interval, time_zone]
            end
          end
        when "SQLite"
          raise Groupdate::Error, "Time zones not supported for SQLite" unless @time_zone.utc_offset.zero?
          raise Groupdate::Error, "day_start not supported for SQLite" unless day_start.zero?
          raise Groupdate::Error, "week_start not supported for SQLite" unless week_start == 6

          if period == :week
            ["strftime('%%Y-%%m-%%d 00:00:00 UTC', #{column}, '-6 days', 'weekday 0')"]
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
                "%Y-%m-%d 00:00:00 UTC"
              when :month
                "%Y-%m-01 00:00:00 UTC"
              when :quarter
                raise Groupdate::Error, "Quarter not supported for SQLite"
              else # year
                "%Y-01-01 00:00:00 UTC"
              end

            ["strftime(?, #{column})", format]
          end
        when "Redshift"
          day_start_interval = "#{day_start} second"

          case period
          when :minute_of_hour
            ["EXTRACT(MINUTE from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :hour_of_day
            ["EXTRACT(HOUR from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :day_of_week
            ["EXTRACT(DOW from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :day_of_month
            ["EXTRACT(DAY from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :day_of_year
            ["EXTRACT(DOY from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :month_of_year
            ["EXTRACT(MONTH from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL ?)::integer", time_zone, day_start_interval]
          when :week # start on Sunday, not Redshift default Monday
            # Redshift does not return timezone information; it
            # always says it is in UTC time, so we must convert
            # back to UTC to play properly with the rest of Groupdate.
            week_start_interval = "#{week_start} day"
            ["CONVERT_TIMEZONE(?, 'Etc/UTC', DATE_TRUNC(?, CONVERT_TIMEZONE(?, #{column}) - INTERVAL ? - INTERVAL ?))::timestamp + INTERVAL ? + INTERVAL ?", time_zone, period, time_zone, day_start_interval, week_start_interval, week_start_interval, day_start_interval]
          else
            ["CONVERT_TIMEZONE(?, 'Etc/UTC', DATE_TRUNC(?, CONVERT_TIMEZONE(?, #{column}) - INTERVAL ?))::timestamp + INTERVAL ?", time_zone, period, time_zone, day_start_interval, day_start_interval]
          end
        else
          raise Groupdate::Error, "Connection adapter not supported: #{adapter_name}"
        end

      clause = @relation.send(:sanitize_sql_array, query)

      # cleaner queries in logs
      clause = clean_group_clause_postgresql(clause)
      clean_group_clause_mysql(clause)
    end

    def clean_group_clause_postgresql(clause)
      clause.gsub(/ (\-|\+) INTERVAL '0 second'/, "")
    end

    def clean_group_clause_mysql(clause)
      clause.gsub(/ (\-|\+) INTERVAL 0 second/, "")
    end

    def where_clause
      if @time_range.is_a?(Range)
        op = @time_range.exclude_end? ? "<" : "<="
        ["#{column} >= ? AND #{column} #{op} ?", @time_range.first, @time_range.last]
      else
        ["#{column} IS NOT NULL"]
      end
    end

    # resolves eagerly
    # need to convert both where_clause (easy)
    # and group_clause (not easy) if want to avoid this
    def resolve_column(relation, column)
      node = relation.send(:relation).send(:arel_columns, [column]).first
      node = Arel::Nodes::SqlLiteral.new(node) if node.is_a?(String)
      relation.connection.visitor.accept(node, Arel::Collectors::SQLString.new).value
    end
  end
end
