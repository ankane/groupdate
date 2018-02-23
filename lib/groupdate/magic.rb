require "i18n"

module Groupdate
  class Magic
    attr_accessor :period, :options, :group_index

    def initialize(period:, **options)
      @period = period
      @options = options

      unknown_keywords = options.keys - [:day_start, :time_zone, :dates, :series, :week_start, :format, :locale, :range, :reverse]
      raise ArgumentError, "unknown keywords: #{unknown_keywords.join(", ")}" if unknown_keywords.any?

      raise Groupdate::Error, "Unrecognized time zone" unless time_zone
      raise Groupdate::Error, "Unrecognized :week_start option" if period == :week && !week_start
    end

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
          if period == :quarter
            step = 3.months
          elsif 1.respond_to?(period)
            step = 1.send(period)
          else
            raise ArgumentError, "Cannot use last option with #{period}"
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

    private

    def generate_series(data, multiple_groups)
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
            sorted_keys.first..sorted_keys.last
          end

        if time_range.first
          series = [round_time(time_range.first)]

          if period == :quarter
            step = 3.months
          else
            step = 1.send(period)
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
    end

    def series(data, default_value: nil, multiple_groups: false, series_default: true)
      reverse = !reverse if options[:reverse]

      series = generate_series(data, multiple_groups)

      series =
        if multiple_groups
          keys = data.keys.map { |k| k[0...group_index] + k[(group_index + 1)..-1] }.uniq
          series = series.to_a.reverse if reverse
          keys.flat_map do |k|
            series.map { |s| k[0...group_index] + [s] + k[group_index..-1] }
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

      use_series = options.key?(:series) ? options[:series] : series_default
      if use_series == false
        series = series.select { |k| data[k] }
      end

      value = 0
      Hash[series.map do |k|
        value = data[k] || (@options[:carry_forward] && value) || default_value
        [multiple_groups ? k[0...group_index] + [key_format.call(k[group_index])] + k[(group_index + 1)..-1] : key_format.call(k), value]
      end]
    end

    def round_time(time)
      time = time.to_time.in_time_zone(time_zone) - day_start.seconds

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

      time.is_a?(Time) ? time + day_start.seconds : time
    end

    class Enumerable < Magic
      def group_by(enum, &_block)
        group = enum.group_by { |v| v = yield(v); v ? round_time(v) : nil }
        series(group, default_value: [], series_default: false)
      end

      def self.group_by(enum, period, options, &block)
        Groupdate::Magic::Enumerable.new(period: period, **options).group_by(enum, &block)
      end
    end

    class Relation < Magic
      def initialize(**options)
        super(**options.reject { |k, _| [:default_value, :carry_forward, :last, :current].include?(k) })
        @options = options
      end

      def perform(relation, result)
        multiple_groups = relation.group_values.size > 1

        cast_method =
          case period
          when :day_of_week
            lambda { |k| (k.to_i - 1 - week_start) % 7 }
          when :hour_of_day, :day_of_month, :month_of_year, :minute_of_hour
            lambda { |k| k.to_i }
          else
            utc = ActiveSupport::TimeZone["UTC"]
            lambda { |k| (k.is_a?(String) || !k.respond_to?(:to_time) ? utc.parse(k.to_s) : k.to_time).in_time_zone(time_zone) }
          end

        missing_time_zone_support = multiple_groups ? (result.keys.first && result.keys.first[group_index].nil?) : result.key?(nil)
        if missing_time_zone_support
          raise Groupdate::Error, "Be sure to install time zone support - https://github.com/ankane/groupdate#for-mysql"
        end
        result = Hash[result.map { |k, v| [multiple_groups ? k[0...group_index] + [cast_method.call(k[group_index])] + k[(group_index + 1)..-1] : cast_method.call(k), v] }]

        series(result, default_value: (options.key?(:default_value) ? options[:default_value] : 0), multiple_groups: multiple_groups)
      end

      def self.generate_relation(relation, field:, **options)
        magic = Groupdate::Magic::Relation.new(**options)

        # generate ActiveRecord relation
        relation =
          RelationBuilder.new(
            relation,
            column: field,
            period: magic.period,
            time_zone: magic.time_zone,
            time_range: magic.time_range,
            week_start: magic.week_start,
            day_start: magic.day_start
          ).generate

        # add Groupdate info
        magic.group_index = relation.group_values.size - 1
        (relation.groupdate_values ||= []) << magic

        relation
      end

      def self.process_result(relation, result)
        relation.groupdate_values.reverse.each do |gv|
          result = gv.perform(relation, result)
        end
        result
      end
    end
  end
end
