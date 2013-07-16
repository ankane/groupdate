module Groupdate
  class Series

    def initialize(relation, field, column, time_zone, time_range, week_start)
      if time_range.is_a?(Range)
        # doesn't matter whether we include the end of a ... range - it will be excluded later
        @relation = relation.where("#{column} >= ? AND #{column} <= ?", time_range.first, time_range.last)
      else
        @relation = relation.where("#{column} IS NOT NULL")
      end
      @field = field
      @time_zone = time_zone
      @time_range = time_range
      @week_start = week_start
    end

    def build_series(count)
      utc = ActiveSupport::TimeZone["UTC"]

      cast_method =
        case @field
        when "day_of_week", "hour_of_day"
          lambda{|k| k.to_i }
        else
          lambda{|k| (k.is_a?(String) ? utc.parse(k) : k.to_time).utc }
        end

      count = Hash[ count.map{|k, v| [cast_method.call(k), v] } ]

      series =
        case @field
        when "day_of_week"
          0..6
        when "hour_of_day"
          0..23
        else
          time_range =
            if @time_range.is_a?(Range)
              @time_range
            else
              # use first and last values
              sorted_keys = count.keys.sort
              sorted_keys.first..sorted_keys.last
            end

          # determine start time
          time = time_range.first.to_time.in_time_zone(@time_zone)
          starts_at =
            case @field
            when "second"
              time.change(:usec => 0)
            when "minute"
              time.change(:sec => 0)
            when "hour"
              time.change(:min => 0)
            when "day"
              time.beginning_of_day
            when "week"
              # same logic as MySQL group
              weekday = (time.wday - 1) % 7
              (time - ((7 - @week_start + weekday) % 7).days).midnight
            when "month"
              time.beginning_of_month
            else # year
              time.beginning_of_year
            end

          series = [starts_at]

          step = 1.send(@field)

          while time_range.cover?(series.last + step)
            series << series.last + step
          end

          series.map{|s| s.to_time.utc }
        end

      Hash[series.map do |k|
        [k, count[k] || 0]
      end]
    end

    def method_missing(method, *args, &block)
      # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/calculations.rb
      if ActiveRecord::Calculations.method_defined?(method)
        build_series(@relation.send(method, *args, &block))
      else
        raise NoMethodError, "valid methods are: #{ActiveRecord::Calculations.instance_methods.join(", ")}"
      end
    end

  end # Series
end
