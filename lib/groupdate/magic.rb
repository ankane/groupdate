require "i18n"

module Groupdate
  class Magic
    attr_accessor :field, :options

    def initialize(field, options)
      @field = field
      @options = options

      raise Groupdate::Error, "Unrecognized time zone" unless time_zone

      raise Groupdate::Error, "Unrecognized :week_start option" if field == :week && !week_start
    end

    def group_by(enum, &_block)
      group = enum.group_by { |v| v = yield(v); v ? round_time(v) : nil }
      series(group, [], false, false, false)
    end

    def relation(column, relation)
      if relation.default_timezone == :local
        raise Groupdate::Error, "ActiveRecord::Base.default_timezone must be :utc to use Groupdate"
      end

      time_zone = self.time_zone.tzinfo.name

      adapter_name = relation.connection.adapter_name
      query =
        case adapter_name
        when "MySQL", "Mysql2", "Mysql2Spatial"
          case field
          when :day_of_week # Sunday = 0, Monday = 1, etc
            # use CONCAT for consistent return type (String)
            ["DAYOFWEEK(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), '+00:00', ?)) - 1", time_zone]
          when :hour_of_day
            ["(EXTRACT(HOUR from CONVERT_TZ(#{column}, '+00:00', ?)) + 24 - #{day_start / 3600}) % 24", time_zone]
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
              case field
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
          case field
          when :day_of_week
            ["EXTRACT(DOW from #{column}::timestamptz AT TIME ZONE ? - INTERVAL '#{day_start} second')::integer", time_zone]
          when :hour_of_day
            ["EXTRACT(HOUR from #{column}::timestamptz AT TIME ZONE ? - INTERVAL '#{day_start} second')::integer", time_zone]
          when :day_of_month
            ["EXTRACT(DAY from #{column}::timestamptz AT TIME ZONE ? - INTERVAL '#{day_start} second')::integer", time_zone]
          when :month_of_year
            ["EXTRACT(MONTH from #{column}::timestamptz AT TIME ZONE ? - INTERVAL '#{day_start} second')::integer", time_zone]
          when :week # start on Sunday, not PostgreSQL default Monday
            ["(DATE_TRUNC('#{field}', (#{column}::timestamptz - INTERVAL '#{week_start} day' - INTERVAL '#{day_start} second') AT TIME ZONE ?) + INTERVAL '#{week_start} day' + INTERVAL '#{day_start} second') AT TIME ZONE ?", time_zone, time_zone]
          else
            ["(DATE_TRUNC('#{field}', (#{column}::timestamptz - INTERVAL '#{day_start} second') AT TIME ZONE ?) + INTERVAL '#{day_start} second') AT TIME ZONE ?", time_zone, time_zone]
          end
        when "SQLite"
          raise Groupdate::Error, "Time zones not supported for SQLite" unless self.time_zone.utc_offset.zero?
          raise Groupdate::Error, "day_start not supported for SQLite" unless day_start.zero?
          raise Groupdate::Error, "week_start not supported for SQLite" unless week_start == 6

          if field == :week
            ["strftime('%%Y-%%m-%%d 00:00:00 UTC', #{column}, '-6 days', 'weekday 0')"]
          else
            format =
              case field
                when :hour_of_day
                  "%H"
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
          case field
          when :day_of_week # Sunday = 0, Monday = 1, etc.
            ["EXTRACT(DOW from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer", time_zone]
          when :hour_of_day
            ["EXTRACT(HOUR from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer", time_zone]
          when :day_of_month
            ["EXTRACT(DAY from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer", time_zone]
          when :month_of_year
            ["EXTRACT(MONTH from CONVERT_TIMEZONE(?, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer", time_zone]
          when :week # start on Sunday, not Redshift default Monday
            # Redshift does not return timezone information; it
            # always says it is in UTC time, so we must convert
            # back to UTC to play properly with the rest of Groupdate.
            #
            ["CONVERT_TIMEZONE(?, 'Etc/UTC', DATE_TRUNC(?, CONVERT_TIMEZONE(?, #{column}) - INTERVAL '#{week_start} day' - INTERVAL '#{day_start} second'))::timestamp + INTERVAL '#{week_start} day' + INTERVAL '#{day_start} second'", time_zone, field, time_zone]
          else
            ["CONVERT_TIMEZONE(?, 'Etc/UTC', DATE_TRUNC(?, CONVERT_TIMEZONE(?, #{column}) - INTERVAL '#{day_start} second'))::timestamp + INTERVAL '#{day_start} second'", time_zone, field, time_zone]
          end
        else
          raise Groupdate::Error, "Connection adapter not supported: #{adapter_name}"
        end

      if adapter_name == "MySQL" && field == :week
        query[0] = "CAST(#{query[0]} AS DATETIME)"
      end

      group = relation.group(Groupdate::OrderHack.new(relation.send(:sanitize_sql_array, query), field, time_zone))
      relation =
        if time_range.is_a?(Range)
          # doesn't matter whether we include the end of a ... range - it will be excluded later
          group.where("#{column} >= ? AND #{column} <= ?", time_range.first, time_range.last)
        else
          group.where("#{column} IS NOT NULL")
        end

      # TODO do not change object state
      @group_index = group.group_values.size - 1

      Groupdate::Series.new(self, relation)
    end

    def perform(relation, method, *args, &block)
      # undo reverse since we do not want this to appear in the query
      reverse = relation.send(:reverse_order_value)
      relation = relation.except(:reverse_order) if reverse
      order = relation.order_values.first
      if order.is_a?(String)
        parts = order.split(" ")
        reverse_order = (parts.size == 2 && (parts[0].to_sym == field || (activerecord42? && parts[0] == "#{relation.quoted_table_name}.#{relation.quoted_primary_key}")) && parts[1].to_s.downcase == "desc")
        if reverse_order
          reverse = !reverse
          relation = relation.reorder(relation.order_values[1..-1])
        end
      end

      multiple_groups = relation.group_values.size > 1

      cast_method =
        case field
        when :day_of_week, :hour_of_day, :day_of_month, :month_of_year
          lambda { |k| k.to_i }
        else
          utc = ActiveSupport::TimeZone["UTC"]
          lambda { |k| (k.is_a?(String) || !k.respond_to?(:to_time) ? utc.parse(k.to_s) : k.to_time).in_time_zone(time_zone) }
        end

      result = relation.send(method, *args, &block)
      missing_time_zone_support = multiple_groups ? (result.keys.first && result.keys.first[@group_index].nil?) : result.key?(nil)
      if missing_time_zone_support
        raise Groupdate::Error, "Be sure to install time zone support - https://github.com/ankane/groupdate#for-mysql"
      end
      result = Hash[result.map { |k, v| [multiple_groups ? k[0...@group_index] + [cast_method.call(k[@group_index])] + k[(@group_index + 1)..-1] : cast_method.call(k), v] }]

      series(result, (options.key?(:default_value) ? options[:default_value] : 0), multiple_groups, reverse)
    end

    protected

    def time_zone
      @time_zone ||= begin
        time_zone = "Etc/UTC" if options[:time_zone] == false
        time_zone ||= options[:time_zone] || Groupdate.time_zone || (Groupdate.time_zone == false && "Etc/UTC") || Time.zone || "Etc/UTC"
        time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone]
      end
    end

    def week_start
      @week_start ||= [:mon, :tue, :wed, :thu, :fri, :sat, :sun].index((options[:week_start] || options[:start] || Groupdate.week_start).to_sym)
    end

    def day_start
      @day_start ||= ((options[:day_start] || Groupdate.day_start).to_f * 3600).round
    end

    def time_range
      @time_range ||= begin
        time_range = options[:range]
        if time_range.is_a?(Range) && time_range.first.is_a?(Date)
          # convert range of dates to range of times
          # use parsing instead of in_time_zone due to Rails < 4
          last = time_zone.parse(time_range.last.to_s)
          last += 1.day unless time_range.exclude_end?
          time_range = Range.new(time_zone.parse(time_range.first.to_s), last, true)
        elsif !time_range && options[:last]
          if field == :quarter
            step = 3.months
          elsif 1.respond_to?(field)
            step = 1.send(field)
          else
            raise ArgumentError, "Cannot use last option with #{field}"
          end
          if step
            now = Time.now
            # loop instead of multiply to change start_at - see #151
            start_at = now
            (options[:last].to_i - 1).times do
              start_at -= step
            end

            time_range =
              if options[:current] == false
                round_time(start_at - step)...round_time(now)
              else
                round_time(start_at)..now
              end
          end
        end
        time_range
      end
    end

    def series(count, default_value, multiple_groups = false, reverse = false, series_default = true)
      reverse = !reverse if options[:reverse]

      series =
        case field
        when :day_of_week
          0..6
        when :hour_of_day
          0..23
        when :day_of_month
          1..31
        when :month_of_year
          1..12
        else
          time_range = self.time_range
          time_range =
            if time_range.is_a?(Range)
              time_range
            else
              # use first and last values
              sorted_keys =
                if multiple_groups
                  count.keys.map { |k| k[@group_index] }.sort
                else
                  count.keys.sort
                end
              sorted_keys.first..sorted_keys.last
            end

          if time_range.first
            series = [round_time(time_range.first)]

            if field == :quarter
              step = 3.months
            else
              step = 1.send(field)
            end

            last_step = series.last
            while (next_step = round_time(last_step + step)) && time_range.cover?(next_step)
              if next_step == last_step
                last_step += step
                next
              end
              series << next_step
              last_step = next_step
            end

            series
          else
            []
          end
        end

      series =
        if multiple_groups
          keys = count.keys.map { |k| k[0...@group_index] + k[(@group_index + 1)..-1] }.uniq
          series = series.to_a.reverse if reverse
          keys.flat_map do |k|
            series.map { |s| k[0...@group_index] + [s] + k[@group_index..-1] }
          end
        else
          series
        end

      # reversed above if multiple groups
      series = series.to_a.reverse if !multiple_groups && reverse

      locale = options[:locale] || I18n.locale
      use_dates = options.key?(:dates) ? options[:dates] : Groupdate.dates
      key_format =
        if options[:format]
          if options[:format].respond_to?(:call)
            options[:format]
          else
            sunday = time_zone.parse("2014-03-02 00:00:00")
            lambda do |key|
              case field
              when :hour_of_day
                key = sunday + key.hours + day_start.seconds
              when :day_of_week
                key = sunday + key.days
              when :day_of_month
                key = Date.new(2014, 1, key).to_time
              when :month_of_year
                key = Date.new(2014, key, 1).to_time
              end
              I18n.localize(key, format: options[:format], locale: locale)
            end
          end
        elsif [:day, :week, :month, :quarter, :year].include?(field) && use_dates
          lambda { |k| k.to_date }
        else
          lambda { |k| k }
        end

      use_series = options.key?(:series) ? options[:series] : series_default
      if use_series == false
        series = series.select { |k| count[k] }
      end

      value = 0
      Hash[series.map do |k|
        value = count[k] || (@options[:carry_forward] && value) || default_value
        [multiple_groups ? k[0...@group_index] + [key_format.call(k[@group_index])] + k[(@group_index + 1)..-1] : key_format.call(k), value]
      end]
    end

    def round_time(time)
      time = time.to_time.in_time_zone(time_zone) - day_start.seconds

      time =
        case field
        when :second
          time.change(usec: 0)
        when :minute
          time.change(sec: 0)
        when :hour
          time.change(min: 0)
        when :day
          time.beginning_of_day
        when :week
          # same logic as MySQL group
          weekday = (time.wday - 1) % 7
          (time - ((7 - week_start + weekday) % 7).days).midnight
        when :month
          time.beginning_of_month
        when :quarter
          time.beginning_of_quarter
        when :year
          time.beginning_of_year
        when :hour_of_day
          time.hour
        when :day_of_week
          time.wday
        when :day_of_month
          time.day
        when :month_of_year
          time.month
        else
          raise Groupdate::Error, "Invalid field"
        end

      time.is_a?(Time) ? time + day_start.seconds : time
    end

    def activerecord42?
      ActiveRecord::VERSION::STRING.starts_with?("4.2.")
    end
  end
end
