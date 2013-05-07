require "groupdate/order_hack"
require "groupdate/series"
require "active_record"

module Groupdate
  module Scopes
    extend ActiveSupport::Concern

    # Pattern from kaminari
    # https://github.com/amatsuda/kaminari/blob/master/lib/kaminari/models/active_record_extension.rb
    included do
      # Future subclasses will pick up the model extension
      class << self
        def inherited_with_groupdate(kls) #:nodoc:
          inherited_without_groupdate kls
          kls.send(:include, ClassMethods) if kls.superclass == ActiveRecord::Base
        end
        alias_method_chain :inherited, :groupdate
      end

      # Existing subclasses pick up the model extension as well
      self.descendants.each do |kls|
        kls.send(:include, ClassMethods) if kls.superclass == ActiveRecord::Base
      end
    end

    module ClassMethods
      extend ActiveSupport::Concern

      included do
        # Field list from
        # http://www.postgresql.org/docs/9.1/static/functions-datetime.html
        time_fields = %w(second minute hour day week month year)
        number_fields = %w(day_of_week hour_of_day)
        (time_fields + number_fields).each do |field|
          # no define_singleton_method in ruby 1.8
          (class << self; self end).send :define_method, :"group_by_#{field}" do |*args|
            column = connection.quote_table_name(args[0])
            time_zone = args[1] || Time.zone || "Etc/UTC"
            if time_zone.is_a?(ActiveSupport::TimeZone) or time_zone = ActiveSupport::TimeZone[time_zone]
              time_zone = time_zone.tzinfo.name
            else
              raise "Unrecognized time zone"
            end
            query =
              case connection.adapter_name
              when "MySQL", "Mysql2"
                case field
                when "day_of_week" # Sunday = 0, Monday = 1, etc
                  # use CONCAT for consistent return type (String)
                  ["DAYOFWEEK(CONVERT_TZ(#{column}, '+00:00', ?)) - 1", time_zone]
                when "hour_of_day"
                  ["EXTRACT(HOUR from CONVERT_TZ(#{column}, '+00:00', ?))", time_zone]
                when "week"
                  ["CONVERT_TZ(DATE_FORMAT(CONVERT_TZ(DATE_SUB(#{column}, INTERVAL (DAYOFWEEK(CONVERT_TZ(#{column}, '+00:00', ?)) - 1) DAY), '+00:00', ?), '%Y-%m-%d 00:00:00'), ?, '+00:00')", time_zone, time_zone, time_zone]
                else
                  format =
                    case field
                    when "second"
                      "%Y-%m-%d %H:%i:%S"
                    when "minute"
                      "%Y-%m-%d %H:%i:00"
                    when "hour"
                      "%Y-%m-%d %H:00:00"
                    when "day"
                      "%Y-%m-%d 00:00:00"
                    when "month"
                      "%Y-%m-01 00:00:00"
                    else # year
                      "%Y-01-01 00:00:00"
                    end

                  ["CONVERT_TZ(DATE_FORMAT(CONVERT_TZ(#{column}, '+00:00', ?), '#{format}'), ?, '+00:00')", time_zone, time_zone]
                end
              when "PostgreSQL"
                case field
                when "day_of_week"
                  ["EXTRACT(DOW from #{column}::timestamptz AT TIME ZONE ?)", time_zone]
                when "hour_of_day"
                  ["EXTRACT(HOUR from #{column}::timestamptz AT TIME ZONE ?)", time_zone]
                when "week" # start on Sunday, not PostgreSQL default Monday
                  ["(DATE_TRUNC('#{field}', (#{column}::timestamptz + INTERVAL '1 day') AT TIME ZONE ?) - INTERVAL '1 day') AT TIME ZONE ?", time_zone, time_zone]
                else
                  ["DATE_TRUNC('#{field}', #{column}::timestamptz AT TIME ZONE ?) AT TIME ZONE ?", time_zone, time_zone]
                end
              else
                raise "Connection adapter not supported: #{connection.adapter_name}"
              end

            group = group(Groupdate::OrderHack.new(sanitize_sql_array(query), field, time_zone))
            if args[2]
              Series.new(group, field, column, time_zone, args[2])
            else
              group
            end
          end
        end
      end
    end
  end
end
