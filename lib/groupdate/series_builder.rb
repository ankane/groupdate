module Groupdate
  class SeriesBuilder
    attr_reader :period, :time_zone, :day_start, :week_start, :options

    CHECK_PERIODS = [:day, :week, :month, :quarter, :year]

    def initialize(period:, time_zone:, day_start:, week_start:, **options)
      @period = period
      @time_zone = time_zone
      @week_start = week_start
      @day_start = day_start
      @options = options
      @round_time = {}
    end

    def generate(data, default_value:, series_default: true, multiple_groups: false, group_index: nil)
      series = generate_series(data, multiple_groups, group_index)
      series = handle_multiple(data, series, multiple_groups, group_index)

      unless entire_series?(series_default)
        series = series.select { |k| data[k] }
      end

      value = 0
      result = Hash[series.map do |k|
        value = data.delete(k) || (@options[:carry_forward] && value) || default_value
        key =
          if multiple_groups
            k[0...group_index] + [key_format.call(k[group_index])] + k[(group_index + 1)..-1]
          else
            key_format.call(k)
          end

        [key, value]
      end]

      # only check for database
      # only checks remaining keys to avoid expensive calls to round_time
      if series_default && CHECK_PERIODS.include?(period)
        check_consistent_time_zone_info(data, multiple_groups, group_index)
      end

      result
    end

    def round_time(time)
      time = time.to_time.in_time_zone(time_zone)

      # only if day_start != 0 for performance
      time -= day_start.seconds if day_start != 0

      time =
        case period
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
        when :minute_of_hour
          time.min
        when :day_of_week
          (time.wday - 1 - week_start) % 7
        when :day_of_month
          time.day
        when :month_of_year
          time.month
        else
          raise Groupdate::Error, "Invalid period"
        end

      # only if day_start != 0 for performance
      time += day_start.seconds if day_start != 0 && time.is_a?(Time)

      time
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
          if period == :quarter
            step = 3.months
          elsif 1.respond_to?(period)
            step = 1.send(period)
          else
            raise ArgumentError, "Cannot use last option with #{period}"
          end
          if step
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

    private

    def now
      @now ||= time_zone.now
    end

    def generate_series(data, multiple_groups, group_index)
      case period
      when :day_of_week
        0..6
      when :hour_of_day
        0..23
      when :minute_of_hour
        0..59
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
                data.keys.map { |k| k[group_index] }.sort
              else
                data.keys.sort
              end

            tr = sorted_keys.first..sorted_keys.last
            if options[:current] == false && sorted_keys.any? && round_time(now) >= tr.last
              tr = tr.first...round_time(now)
            end
            tr
          end

        if time_range.first
          series = [round_time(time_range.first)]

          if period == :quarter
            step = 3.months
          else
            step = 1.send(period)
          end

          last_step = series.last
          loop do
            next_step = last_step + step
            next_step = round_time(next_step) if next_step.hour != day_start # add condition to speed up
            break unless time_range.cover?(next_step)

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
    end

    def key_format
      locale = options[:locale] || I18n.locale
      use_dates = options.key?(:dates) ? options[:dates] : Groupdate.dates

      if options[:format]
        if options[:format].respond_to?(:call)
          options[:format]
        else
          sunday = time_zone.parse("2014-03-02 00:00:00")
          lambda do |key|
            case period
            when :hour_of_day
              key = sunday + key.hours + day_start.seconds
            when :minute_of_hour
              key = sunday + key.minutes + day_start.seconds
            when :day_of_week
              key = sunday + key.days + (week_start + 1).days
            when :day_of_month
              key = Date.new(2014, 1, key).to_time
            when :month_of_year
              key = Date.new(2014, key, 1).to_time
            end
            I18n.localize(key, format: options[:format], locale: locale)
          end
        end
      elsif [:day, :week, :month, :quarter, :year].include?(period) && use_dates
        lambda { |k| k.to_date }
      else
        lambda { |k| k }
      end
    end

    def handle_multiple(data, series, multiple_groups, group_index)
      reverse = options[:reverse]

      if multiple_groups
        keys = data.keys.map { |k| k[0...group_index] + k[(group_index + 1)..-1] }.uniq
        series = series.to_a.reverse if reverse
        keys.flat_map do |k|
          series.map { |s| k[0...group_index] + [s] + k[group_index..-1] }
        end
      elsif reverse
        series.to_a.reverse
      else
        series
      end
    end

    def check_consistent_time_zone_info(data, multiple_groups, group_index)
      keys = data.keys
      if multiple_groups
        keys.map! { |k| k[group_index] }
        keys.uniq!
      end

      keys.each do |key|
        if key != round_time(key)
          # only need to show what database returned since it will cast in Ruby time zone
          raise Groupdate::Error, "Database and Ruby have inconsistent time zone info. Database returned #{key}"
        end
      end
    end

    def entire_series?(series_default)
      options.key?(:series) ? options[:series] : series_default
    end
  end
end
