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

    def series_builder
      @series_builder ||=
        SeriesBuilder.new(
          **options,
          period: period,
          time_zone: time_zone,
          day_start: day_start,
          week_start: week_start
        )
    end

    def time_range
      series_builder.time_range
    end

    class Enumerable < Magic
      def group_by(enum, &_block)
        group = enum.group_by { |v| v = yield(v); v ? series_builder.round_time(v) : nil }
        series_builder.generate(group, default_value: [], series_default: false)
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

        check_time_zone_support(result, multiple_groups)
        result = cast_result(result, multiple_groups)

        series_builder.generate(
          result,
          default_value: options.key?(:default_value) ? options[:default_value] : 0,
          multiple_groups: multiple_groups,
          group_index: group_index
        )
      end

      def cast_method
        case period
        when :day_of_week
          lambda { |k| (k.to_i - 1 - week_start) % 7 }
        when :hour_of_day, :day_of_month, :month_of_year, :minute_of_hour
          lambda { |k| k.to_i }
        else
          utc = ActiveSupport::TimeZone["UTC"]
          lambda { |k| (k.is_a?(String) || !k.respond_to?(:to_time) ? utc.parse(k.to_s) : k.to_time).in_time_zone(time_zone) }
        end
      end

      def cast_result(result, multiple_groups)
        Hash[result.map { |k, v| [multiple_groups ? k[0...group_index] + [cast_method.call(k[group_index])] + k[(group_index + 1)..-1] : cast_method.call(k), v] }]
      end

      def check_time_zone_support(result, multiple_groups)
        missing_time_zone_support = multiple_groups ? (result.keys.first && result.keys.first[group_index].nil?) : result.key?(nil)
        if missing_time_zone_support
          raise Groupdate::Error, "Be sure to install time zone support - https://github.com/ankane/groupdate#for-mysql"
        end
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
