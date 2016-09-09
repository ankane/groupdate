require "i18n"

module Groupdate
  class Magic
    attr_accessor :field, :options

    def initialize(field, options)
      @field = field
      @options = options

      raise "Unrecognized time zone" unless time_zone

      raise "Unrecognized :week_start option" if field == :week && !week_start

      if field == :time_range && [:time_range_end, :time_range_length, :time_ranges_count].any? { |o| options[o].blank? }
        raise "You need to provide :time_range_end, :time_range_length and :time_ranges_count"
      end
    end

    def group_by(enum, &_block)
      group = enum.group_by { |v| v = yield(v); v ? round_time(v) : nil }
      series(group, [], false, false, false)
    end

    def time_zone_name
      @time_zone_name ||= self.time_zone.tzinfo.name
    end

    def database_time_zone_name
      @database_time_zone_name ||= self.database_time_zone.tzinfo.name
    end

    def query_with_timezone(query, options = {})
      [query, options.merge(database_time_zone: database_time_zone_name, time_zone: time_zone_name)]
    end

    def relation(column, relation)
      adapter_name = relation.connection.adapter_name
      klass = relation

      if field == :time_range
        time_series = ranges.map { |day| "CONVERT_TZ('#{day}', :database_time_zone, :time_zone)" }
        time_series_subquery = time_series.map { |day| "select #{day} as day" }.join(" union ")
        join_query = klass.send(:sanitize_sql_array, ["CROSS JOIN (SELECT sub.day FROM (#{time_series_subquery}) sub) joined ON #{column} > joined.day AND #{column} < DATE_ADD(joined.day, INTERVAL :time_range_length SECOND)",
                                  time_range_length: options[:time_range_length], time_zone: time_zone_name, database_time_zone: database_time_zone_name])
        relation = relation.joins(join_query)
      end

      query =
        case adapter_name
        when "MySQL", "Mysql2", "Mysql2Spatial"
          case field
          when :day_of_week # Sunday = 0, Monday = 1, etc
            # use CONCAT for consistent return type (String)
            query_with_timezone("DAYOFWEEK(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), :database_time_zone, :time_zone)) - 1")
          when :hour_of_day
            query_with_timezone("(EXTRACT(HOUR from CONVERT_TZ(#{column}, :database_time_zone, :time_zone)) + 24 - #{day_start / 3600}) % 24")
          when :day_of_month
            query_with_timezone("DAYOFMONTH(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), :database_time_zone, :time_zone))")
          when :month_of_year
            query_with_timezone("MONTH(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), :database_time_zone, :time_zone))")
          when :week
            query_with_timezone("CONVERT_TZ(DATE_FORMAT(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL ((#{7 - week_start} + WEEKDAY(CONVERT_TZ(#{column}, :database_time_zone, :time_zone) - INTERVAL #{day_start} second)) % 7) DAY) - INTERVAL #{day_start} second, :database_time_zone, :time_zone), '%Y-%m-%d 00:00:00') + INTERVAL #{day_start} second, :time_zone, :database_time_zone)")
          when :time_range
            query_with_timezone("CONVERT_TZ(joined.day, :time_zone, :database_time_zone)")
          when :quarter
            query_with_timezone("DATE_ADD(CONVERT_TZ(DATE_FORMAT(DATE(CONCAT(EXTRACT(YEAR FROM CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), :database_time_zone, :time_zone)), '-', LPAD(1 + 3 * (QUARTER(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), :database_time_zone, :time_zone)) - 1), 2, '00'), '-01')), '%Y-%m-%d %H:%i:%S'), :time_zone, :database_time_zone), INTERVAL #{day_start} second)")
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

            query_with_timezone("DATE_ADD(CONVERT_TZ(DATE_FORMAT(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL #{day_start} second), :database_time_zone, :time_zone), '#{format}'), :time_zone, :database_time_zone), INTERVAL #{day_start} second)")
          end
        when "PostgreSQL", "PostGIS"
          case field
          when :day_of_week
            query_with_timezone("EXTRACT(DOW from #{column}::timestamptz AT TIME ZONE :time_zone - INTERVAL '#{day_start} second')::integer")
          when :hour_of_day
            query_with_timezone("EXTRACT(HOUR from #{column}::timestamptz AT TIME ZONE :time_zone - INTERVAL '#{day_start} second')::integer")
          when :day_of_month
            query_with_timezone("EXTRACT(DAY from #{column}::timestamptz AT TIME ZONE :time_zone - INTERVAL '#{day_start} second')::integer")
          when :month_of_year
            query_with_timezone("EXTRACT(MONTH from #{column}::timestamptz AT TIME ZONE :time_zone - INTERVAL '#{day_start} second')::integer")
          when :week # start on Sunday, not PostgreSQL default Monday
            query_with_timezone("(DATE_TRUNC('#{field}', (#{column}::timestamptz - INTERVAL '#{week_start} day' - INTERVAL '#{day_start} second') AT TIME ZONE :time_zone) + INTERVAL '#{week_start} day' + INTERVAL '#{day_start} second') AT TIME ZONE :time_zone")
          else
            query_with_timezone("(DATE_TRUNC('#{field}', (#{column}::timestamptz - INTERVAL '#{day_start} second') AT TIME ZONE :time_zone) + INTERVAL '#{day_start} second') AT TIME ZONE :time_zone")
          end
        when "Redshift"
          case field
          when :day_of_week # Sunday = 0, Monday = 1, etc.
            query_with_timezone("EXTRACT(DOW from CONVERT_TIMEZONE(:time_zone, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer")
          when :hour_of_day
            query_with_timezone("EXTRACT(HOUR from CONVERT_TIMEZONE(:time_zone, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer")
          when :day_of_month
            query_with_timezone("EXTRACT(DAY from CONVERT_TIMEZONE(:time_zone, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer")
          when :month_of_year
            query_with_timezone("EXTRACT(MONTH from CONVERT_TIMEZONE(:time_zone, #{column}::timestamp) - INTERVAL '#{day_start} second')::integer")
          when :week # start on Sunday, not Redshift default Monday
            # Redshift does not return timezone information; it
            # always says it is in UTC time, so we must convert
            # back to UTC to play properly with the rest of Groupdate.
            #
            query_with_timezone("CONVERT_TIMEZONE(:time_zone, 'Etc/UTC', DATE_TRUNC(:field, CONVERT_TIMEZONE(:time_zone, #{column}) - INTERVAL '#{week_start} day' - INTERVAL '#{day_start} second'))::timestamp + INTERVAL '#{week_start} day' + INTERVAL '#{day_start} second'", field: field)
          else
            query_with_timezone("CONVERT_TIMEZONE(:time_zone, 'Etc/UTC', DATE_TRUNC(:field, CONVERT_TIMEZONE(:time_zone, #{column}) - INTERVAL '#{day_start} second'))::timestamp + INTERVAL '#{day_start} second'", field: field)
          end
        else
          raise "Connection adapter not supported: #{adapter_name}"
        end

      if adapter_name == "MySQL" && field == :week
        query[0] = "CAST(#{query[0]} AS DATETIME)"
      end

      group = relation.group(Groupdate::OrderHack.new(klass.send(:sanitize_sql_array, query), field, time_zone_name))
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
          lambda { |k| (k.is_a?(String) || !k.respond_to?(:to_time) ? database_time_zone.parse(k.to_s) : k.to_time).in_time_zone(time_zone) }
        end

      count =
        begin
          Hash[relation.send(method, *args, &block).map { |k, v| [multiple_groups ? k[0...@group_index] + [cast_method.call(k[@group_index])] + k[(@group_index + 1)..-1] : cast_method.call(k), v] }]
        rescue NoMethodError
          raise "Be sure to install time zone support - https://github.com/ankane/groupdate#for-mysql"
        end

      series(count, (options.key?(:default_value) ? options[:default_value] : 0), multiple_groups, reverse)
    end

    protected

    def database_time_zone
      @database_time_zone ||= begin
        database_time_zone = options[:database_time_zone] || Groupdate.database_time_zone || Time.zone || "Etc/UTC"
        database_time_zone.is_a?(ActiveSupport::TimeZone) ? database_time_zone : ActiveSupport::TimeZone[database_time_zone]
      end
    end

    def time_zone
      @time_zone ||= begin
        time_zone = options[:time_zone] || Groupdate.time_zone || Time.zone || "Etc/UTC"
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
        if !time_range && options[:last]
          step = 1.send(field) if 1.respond_to?(field)
          if step
            now = Time.now
            now -= step if options[:current] == false
            time_range = round_time(now - (options[:last].to_i - 1).send(field))..now
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
        when :time_range
          ranges
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
        elsif [:day, :week, :month, :quarter, :year, :time_range].include?(field) && use_dates
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

    def ranges
      options[:time_ranges_count].times.map { |r| options[:time_range_end].to_time.in_time_zone(database_time_zone) - (r + 1) * options[:time_range_length] }
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
        when :time_range
          ranges.detect { |r| time > r && time < r + options[:time_range_length] }
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
          raise "Invalid field"
        end

      time.is_a?(Time) ? time + day_start.seconds : time
    end

    def activerecord42?
      ActiveRecord::VERSION::STRING.starts_with?("4.2.")
    end
  end
end
