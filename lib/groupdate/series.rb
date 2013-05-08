module Groupdate
  class Series

    def initialize(relation, field, column, time_zone, time_range)
      @relation = relation
      if time_range.is_a?(Range)
        @relation = relation.where("#{column} BETWEEN ? AND ?", time_range.first, time_range.last)
      end
      @field = field
      @time_zone = time_zone
      @time_range = time_range
    end

    def build_series(count)
      cast_method =
        case @field
        when "day_of_week", "hour_of_day"
          lambda{|k| k.to_i }
        else
          lambda{|k| k.is_a?(Time) ? k : Time.parse(k) }
        end

      count = Hash[count.map do |k, v|
        [cast_method.call(k), v]
      end]

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
          time = time_range.first.in_time_zone(@time_zone)
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
              time.beginning_of_week(:sunday)
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

          series.map{|s| s.to_time }
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
