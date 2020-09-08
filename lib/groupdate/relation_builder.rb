module Groupdate
  class RelationBuilder
    attr_reader :period, :column, :day_start, :week_start, :n_seconds

    def initialize(relation, column:, period:, time_zone:, time_range:, week_start:, day_start:, n_seconds:)
      # very important
      validate_column(column)

      @relation = relation
      @column = resolve_column(relation, column)
      @period = period
      @time_zone = time_zone
      @time_range = time_range
      @week_start = week_start
      @day_start = day_start
      @n_seconds = n_seconds

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
          day_start_column = "CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second"

          case period
          when :minute_of_hour
            ["MINUTE(#{day_start_column})", time_zone, day_start]
          when :hour_of_day
            ["HOUR(#{day_start_column})", time_zone, day_start]
          when :day_of_week
            ["DAYOFWEEK(#{day_start_column}) - 1", time_zone, day_start]
          when :day_of_month
            ["DAYOFMONTH(#{day_start_column})", time_zone, day_start]
          when :day_of_year
            ["DAYOFYEAR(#{day_start_column})", time_zone, day_start]
          when :month_of_year
            ["MONTH(#{day_start_column})", time_zone, day_start]
          when :week
            ["CONVERT_TZ(DATE_FORMAT(#{day_start_column} - INTERVAL ((? + DAYOFWEEK(#{day_start_column})) % 7) DAY, '%Y-%m-%d 00:00:00') + INTERVAL ? second, ?, '+00:00')", time_zone, day_start, 12 - week_start, time_zone, day_start, day_start, time_zone]
          when :quarter
            ["CONVERT_TZ(DATE_FORMAT(DATE(CONCAT(YEAR(#{day_start_column}), '-', LPAD(1 + 3 * (QUARTER(#{day_start_column}) - 1), 2, '00'), '-01')), '%Y-%m-%d %H:%i:%S') + INTERVAL ? second, ?, '+00:00')", time_zone, day_start, time_zone, day_start, day_start, time_zone]
          when :custom
            ["FROM_UNIXTIME((UNIX_TIMESTAMP(#{column}) DIV ?) * ?)", n_seconds, n_seconds]
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

            ["CONVERT_TZ(DATE_FORMAT(#{day_start_column}, ?) + INTERVAL ? second, ?, '+00:00')", time_zone, day_start, format, day_start, time_zone]
          end
        when "PostgreSQL", "PostGIS"
          day_start_column = "#{column}::timestamptz AT TIME ZONE ? - INTERVAL ?"
          day_start_interval = "#{day_start} second"

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
        when "SQLite"
          raise Groupdate::Error, "Time zones not supported for SQLite" unless @time_zone.utc_offset.zero?
          raise Groupdate::Error, "day_start not supported for SQLite" unless day_start.zero?

          if period == :week
            ["strftime('%Y-%m-%d 00:00:00 UTC', #{column}, '-6 days', ?)", "weekday #{(week_start + 1) % 7}"]
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
          day_start_column = "CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL ?"
          day_start_interval = "#{day_start} second"

          case period
          when :minute_of_hour
            ["EXTRACT(MINUTE from #{day_start_column})::integer", time_zone, day_start_interval]
          when :hour_of_day
            ["EXTRACT(HOUR from #{day_start_column})::integer", time_zone, day_start_interval]
          when :day_of_week
            ["EXTRACT(DOW from #{day_start_column})::integer", time_zone, day_start_interval]
          when :day_of_month
            ["EXTRACT(DAY from #{day_start_column})::integer", time_zone, day_start_interval]
          when :day_of_year
            ["EXTRACT(DOY from #{day_start_column})::integer", time_zone, day_start_interval]
          when :month_of_year
            ["EXTRACT(MONTH from #{day_start_column})::integer", time_zone, day_start_interval]
          when :week # start on Sunday, not Redshift default Monday
            # Redshift does not return timezone information; it
            # always says it is in UTC time, so we must convert
            # back to UTC to play properly with the rest of Groupdate.
            week_start_interval = "#{week_start} day"
            ["CONVERT_TIMEZONE(?, 'Etc/UTC', DATE_TRUNC('week', #{day_start_column} - INTERVAL ?) + INTERVAL ? + INTERVAL ?)::timestamp", time_zone, time_zone, day_start_interval, week_start_interval, week_start_interval, day_start_interval]
          when :custom
            raise Groupdate::Error, "Not implemented yet"
          else
            ["CONVERT_TIMEZONE(?, 'Etc/UTC', DATE_TRUNC(?, #{day_start_column}) + INTERVAL ?)::timestamp", time_zone, period, time_zone, day_start_interval, day_start_interval]
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
        if @time_range.end
          op = @time_range.exclude_end? ? "<" : "<="
          if @time_range.begin
            ["#{column} >= ? AND #{column} #{op} ?", @time_range.begin, @time_range.end]
          else
            ["#{column} #{op} ?", @time_range.end]
          end
        else
          ["#{column} >= ?", @time_range.begin]
        end
      else
        ["#{column} IS NOT NULL"]
      end
    end

    # basic version of Active Record disallow_raw_sql!
    # symbol = column (safe), Arel node = SQL (safe), other = untrusted
    def validate_column(column)
      # matches table.column and column
      unless column.is_a?(Symbol) || column.is_a?(Arel::Nodes::SqlLiteral) || /\A\w+(\.\w+)?\z/i.match(column.to_s)
        warn "[groupdate] Non-attribute argument: #{column}. Use Arel.sql() for known-safe values. This will raise an error in Groupdate 6"
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
