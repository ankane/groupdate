require "i18n"

module Groupdate
  class Magic
    DAYS = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

    attr_accessor :period, :options, :group_index

    def initialize(period:, **options)
      @period = period
      @options = options

      validate_keywords
      validate_arguments
    end

    def validate_keywords
      known_keywords = [:time_zone, :dates, :series, :format, :locale, :range, :reverse, :series_label]

      if %i[week day_of_week].include?(period)
        known_keywords << :week_start
      end

      if %i[day week month quarter year day_of_week hour_of_day day_of_month day_of_year month_of_year].include?(period)
        known_keywords << :day_start
      else
        # prevent Groupdate.day_start from applying
        @day_start = 0
      end

      unknown_keywords = options.keys - known_keywords
      raise ArgumentError, "unknown keywords: #{unknown_keywords.join(", ")}" if unknown_keywords.any?
    end

    def validate_arguments
      # TODO better messages
      raise ArgumentError, "Unrecognized time zone" unless time_zone
      raise ArgumentError, "Unrecognized :week_start option" unless week_start
      raise ArgumentError, "Cannot use endless range for :range option" if options[:range].is_a?(Range) && !options[:range].end
      raise ArgumentError, ":day_start must be between 0 and 24" if (day_start / 3600) < 0 || (day_start / 3600) >= 24
    end

    def time_zone
      @time_zone ||= begin
        time_zone = "Etc/UTC" if options[:time_zone] == false
        time_zone ||= options[:time_zone] || Groupdate.time_zone || (Groupdate.time_zone == false && "Etc/UTC") || Time.zone || "Etc/UTC"
        time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone]
      end
    end

    def week_start
      @week_start ||= begin
        v = (options[:week_start] || Groupdate.week_start).to_sym
        DAYS.index(v) || [:mon, :tue, :wed, :thu, :fri, :sat, :sun].index(v)
      end
    end

    def day_start
      @day_start ||= ((options[:day_start] || Groupdate.day_start).to_f * 3600).round
    end

    def series_label
      @series_label ||= (options[:series_label].present? ? options[:series_label] : nil)
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

    def self.validate_period(period, permit)
      permitted_periods = ((permit || Groupdate::PERIODS).map(&:to_sym) & Groupdate::PERIODS).map(&:to_s)
      raise ArgumentError, "Unpermitted period" unless permitted_periods.include?(period.to_s)
    end

    class Enumerable < Magic
      def group_by(enum, &_block)
        group = enum.group_by do |v|
          v = yield(v)
          raise ArgumentError, "Not a time" unless v.respond_to?(:to_time)
          series_builder.round_time(v)
        end
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

      def perform(relation, result, default_value:)
        multiple_groups = relation.group_values.size > 1

        check_nils(result, multiple_groups, relation)
        result = cast_result(result, multiple_groups)

        series_builder.generate(
          result,
          default_value: options.key?(:default_value) ? options[:default_value] : default_value,
          multiple_groups: multiple_groups,
          group_index: group_index
        )
      end

      def cast_method
        @cast_method ||= begin
          case period
          when :minute_of_hour, :hour_of_day, :day_of_month, :day_of_year, :month_of_year
            lambda { |k| k.to_i }
          when :day_of_week
            lambda { |k| (k.to_i - 1 - week_start) % 7 }
          else
            utc = ActiveSupport::TimeZone["UTC"]
            lambda { |k| (k.is_a?(String) || !k.respond_to?(:to_time) ? utc.parse(k.to_s) : k.to_time).in_time_zone(time_zone) }
          end
        end
      end

      def cast_result(result, multiple_groups)
        new_result = {}
        result.each do |k, v|
          if multiple_groups
            k[group_index] = cast_method.call(k[group_index])
          else
            k = cast_method.call(k)
          end
          new_result[k] = v
        end
        new_result
      end

      def time_zone_support?(relation)
        if relation.connection.adapter_name =~ /mysql/i
          # need to call klass for Rails < 5.2
          sql = relation.klass.send(:sanitize_sql_array, ["SELECT CONVERT_TZ(NOW(), '+00:00', ?)", time_zone.tzinfo.name])
          !relation.connection.select_all(sql).first.values.first.nil?
        else
          true
        end
      end

      def check_nils(result, multiple_groups, relation)
        has_nils = multiple_groups ? (result.keys.first && result.keys.first[group_index].nil?) : result.key?(nil)
        if has_nils
          if time_zone_support?(relation)
            raise Groupdate::Error, "Invalid query - be sure to use a date or time column"
          else
            raise Groupdate::Error, "Database missing time zone support for #{time_zone.tzinfo.name} - see https://github.com/ankane/groupdate#for-mysql"
          end
        end
      end

      def perform_series_label(relation, result)
        label = options[:series_label]
        return result unless label.present?

        result.map do |r|
          r.send("#{label}=", cast_series_label(r.send(label)))
          r
        end
      end

      def cast_series_label(original_label)
        series_builder.format_series_label(cast_method.call(original_label))
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
            day_start: magic.day_start,
            series_label: magic.series_label
          ).generate

        # add Groupdate info
        magic.group_index = relation.group_values.size - 1
        (relation.groupdate_values ||= []) << magic

        relation
      end

      # allow any options to keep flexible for future
      def self.process_result(relation, result, **options)
        relation.groupdate_values.reverse.each do |gv|
          result = gv.perform(relation, result, default_value: options[:default_value])
        end
        result
      end

      def self.process_series_label(relation, result)
        relation.groupdate_values.reverse.each do |gv|
          result = gv.perform_series_label(relation, result)
        end
        result
      end
    end
  end
end
