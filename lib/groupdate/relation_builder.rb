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
        when "MySQL", "Mysql2", "Mysql2Spatial", 'Mysql2Rgeo'
          case period
          when :day_of_week
            ["DAYOFWEEK(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), '+00:00', ?)) - 1", time_zone]
          when :hour_of_day
            ["(EXTRACT(HOUR from CONVERT_TZ(#{column}, '+00:00', ?)) + 24 - #{day_start / 3600}) % 24", time_zone]
          when :minute_of_hour
            ["(EXTRACT(MINUTE from CONVERT_TZ(#{column}, '+00:00', ?)))", time_zone]
          when :day_of_month
            ["DAYOFMONTH(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), '+00:00', ?))", time_zone]
          when :month_of_year
            ["MONTH(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), '+00:00', ?))", time_zone]
          when :week
            ["CONVERT_TZ(DATE_FORMAT(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL ((#{7 - week_start} + WEEKDAY(CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL #{day_start} second)) % 7) DAY) - INTERVAL #{day_start} second, '+00:00', ?), '%Y-%m-%d 00:00:00') + INTERVAL #{day_start} second, ?, '+00:00')", time_zone, time_zone, time_zone]
          when :quarter
            ["DATE_ADD(CONVERT_TZ(DATE_FORMAT(DATE(CONCAT(EXTRACT(YEAR FROM CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), '+00:00', ?)), '-', LPAD(1 + 3 * (QUARTER(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), '+00:00', ?)) - 1), 2, '00'), '-01')), '%Y-%m-%d %H:%i:%S'), ?, '+00:00'), INTERVAL #{day_start} second)", time_zone, time_zone, time_zone]
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

            ["DATE_ADD(CONVERT_TZ(DATE_FORMAT(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), '+00:00', ?), '#{format}'), ?, '+00:00'), INTERVAL #{day_start} second)", time_zone, time_zone]
          end
        when "PostgreSQL", "PostGIS"
          case period
          when :day_of_week
            ["EXTRACT(DOW from #{column}::timestamptz AT TIME ZONE ? - INTERVAL '#{day_start} second')::integer", time_zone]
          when :hour_of_day
            ["EXTRACT(HOUR from #{column}::timestamptz AT TIME ZONE ? - INTERVAL '#{day_start} second')::integer", time_zone]
          when :minute_of_hour
            ["EXTRACT(MINUTE from #{column}::timestamptz AT TIME ZONE ? - INTERVAL '#{day_start} second')::integer", time_zone]
          when :day_of_month
            ["EXTRACT(DAY from #{column}::timestamptz AT TIME ZONE ? - INTERVAL '#{day_start} second')::integer", time_zone]
          when :month_of_year
            ["EXTRACT(MONTH from #{column}::timestamptz AT TIME ZONE ? - INTERVAL '#{day_start} second')::integer", time_zone]
          when :week # start on Sunday, not PostgreSQL default Monday
            ["(DATE_TRUNC('#{period}', (#{column}::timestamptz - INTERVAL '#{week_start} day' - INTERVAL '#{day_start} second') AT TIME ZONE ?) + INTERVAL '#{week_start} day' + INTERVAL '#{day_start} second') AT TIME ZONE ?", time_zone, time_zone]
          else
            ["(DATE_TRUNC('#{period}', (#{column}::timestamptz - INTERVAL '#{day_start} second') AT TIME ZONE ?) + INTERVAL '#{day_start} second') AT TIME ZONE ?", time_zone, time_zone]
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
              when :hour_of_day
                "%H"
              when :minute_of_hour
                "%M"
              when :day_of_week
                "%w"
              when :day_of_month
                "%d"
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

            ["strftime('#{format.gsub(/%/, '%%')}', #{column})"]
          end
        when "Redshift"
          case period
          when :day_of_week
            ["EXTRACT(DOW from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer", time_zone]
          when :hour_of_day
            ["EXTRACT(HOUR from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer", time_zone]
          when :minute_of_hour
            ["EXTRACT(MINUTE from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer", time_zone]
          when :day_of_month
            ["EXTRACT(DAY from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer", time_zone]
          when :month_of_year
            ["EXTRACT(MONTH from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer", time_zone]
          when :week # start on Sunday, not Redshift default Monday
            # Redshift does not return timezone information; it
            # always says it is in UTC time, so we must convert
            # back to UTC to play properly with the rest of Groupdate.
            #
            ["CONVERT_TIMEZONE(?, 'Etc/UTC', DATE_TRUNC(?, CONVERT_TIMEZONE(?, #{column}) - INTERVAL '#{week_start} day' - INTERVAL '#{day_start} second'))::timestamp + INTERVAL '#{week_start} day' + INTERVAL '#{day_start} second'", time_zone, period, time_zone]
          else
            ["CONVERT_TIMEZONE(?, 'Etc/UTC', DATE_TRUNC(?, CONVERT_TIMEZONE(?, #{column}) - INTERVAL '#{day_start} second'))::timestamp + INTERVAL '#{day_start} second'", time_zone, period, time_zone]
          end
        else
          raise Groupdate::Error, "Connection adapter not supported: #{adapter_name}"
        end

      if adapter_name == "MySQL" && period == :week
        query[0] = "CAST(#{query[0]} AS DATETIME)"
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
      clause = clause.gsub("DATE_SUB(#{column}, INTERVAL 0 second)", "#{column}")
      if clause.start_with?("DATE_ADD(") && clause.end_with?(", INTERVAL 0 second)")
        clause = clause[9..-21]
      end
      clause
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
