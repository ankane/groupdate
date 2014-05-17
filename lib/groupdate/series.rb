module Groupdate
  class Series
    attr_accessor :relation

    def initialize(relation, field, column, time_zone, time_range, week_start, day_start, group_index, options)
      @relation = relation
      @field = field
      @column = column
      @time_zone = time_zone
      @time_range = time_range
      @week_start = week_start
      @day_start = day_start
      @group_index = group_index
      @options = options
    end

    def perform(method, *args, &block)
      utc = ActiveSupport::TimeZone["UTC"]

      time_range = @time_range
      if !time_range.is_a?(Range) and @options[:last]
        step = 1.send(@field) if 1.respond_to?(@field)
        if step
          now = Time.now
          time_range = round_time(now - (@options[:last].to_i - 1).send(@field))..now
        end
      end

      relation =
        if time_range.is_a?(Range)
          # doesn't matter whether we include the end of a ... range - it will be excluded later
          @relation.where("#{@column} >= ? AND #{@column} <= ?", time_range.first, time_range.last)
        else
          @relation.where("#{@column} IS NOT NULL")
        end

      # undo reverse since we do not want this to appear in the query
      reverse = relation.reverse_order_value
      if reverse
        relation = relation.reverse_order
      end
      order = relation.order_values.first
      if order.is_a?(String)
        parts = order.split(" ")
        reverse_order = (parts.size == 2 && parts[0] == @field && parts[1].to_s.downcase == "desc")
        reverse = !reverse if reverse_order
      end

      multiple_groups = relation.group_values.size > 1

      cast_method =
        case @field
        when "day_of_week", "hour_of_day"
          lambda{|k| k.to_i }
        else
          lambda{|k| (k.is_a?(String) ? utc.parse(k) : k.to_time).in_time_zone(@time_zone) }
        end

      count =
        begin
          Hash[ relation.send(method, *args, &block).map{|k, v| [multiple_groups ? k[0...@group_index] + [cast_method.call(k[@group_index])] + k[(@group_index + 1)..-1] : cast_method.call(k), v] } ]
        rescue NoMethodError
          raise "Be sure to install time zone support - https://github.com/ankane/groupdate#for-mysql"
        end

      series =
        case @field
        when "day_of_week"
          0..6
        when "hour_of_day"
          0..23
        else
          time_range =
            if time_range.is_a?(Range)
              time_range
            else
              # use first and last values
              sorted_keys =
                if multiple_groups
                  count.keys.map{|k| k[@group_index] }.sort
                else
                  count.keys.sort
                end
              sorted_keys.first..sorted_keys.last
            end

          if time_range.first
            series = [round_time(time_range.first)]

            step = 1.send(@field)

            while time_range.cover?(series.last + step)
              series << series.last + step
            end

            if multiple_groups
              keys = count.keys.map{|k| k[0...@group_index] + k[(@group_index + 1)..-1] }.uniq
              series = series.reverse if reverse
              keys.flat_map do |k|
                series.map{|s| k[0...@group_index] + [s] + k[@group_index..-1] }
              end
            else
              series
            end
          else
            []
          end
        end

      # reversed above if multiple groups
      if !multiple_groups and reverse
        series = series.to_a.reverse
      end

      key_format =
        if @options[:format]
          if @options[:format].respond_to?(:call)
            @options[:format]
          else
            sunday = @time_zone.parse("2014-03-02 00:00:00")
            lambda do |key|
              case @field
              when "hour_of_day"
                key = sunday + key.hours + @day_start.hours
              when "day_of_week"
                key = sunday + key.days
              end
              key.strftime(@options[:format].to_s)
            end
          end
        else
          lambda{|k| k }
        end

      Hash[series.map do |k|
        [multiple_groups ? k[0...@group_index] + [key_format.call(k[@group_index])] + k[(@group_index + 1)..-1] : key_format.call(k), count[k] || 0]
      end]
    end

    def round_time(time)
      time = time.to_time.in_time_zone(@time_zone) - @day_start.hours

      time =
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

      time + @day_start.hours
    end

    def clone
      Groupdate::Series.new(@relation, @field, @column, @time_zone, @time_range, @week_start, @day_start, @group_index, @options)
    end

    # clone to prevent modifying original variables
    def method_missing(method, *args, &block)
      # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/calculations.rb
      if ActiveRecord::Calculations.method_defined?(method)
        clone.perform(method, *args, &block)
      elsif @relation.respond_to?(method)
        series = clone
        series.relation = @relation.send(method, *args, &block)
        series
      else
        super
      end
    end

    def respond_to?(method, include_all = false)
      ActiveRecord::Calculations.method_defined?(method) || @relation.respond_to?(method) || super
    end

  end # Series
end
