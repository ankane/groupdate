module Groupdate
  module Adapters
    class BaseAdapter
      attr_reader :period, :column, :day_start, :week_start, :n_seconds

      def initialize(relation, column:, period:, time_zone:, time_range:, week_start:, day_start:, n_seconds:, adapter_name: nil, timezone_aware_column: false)
        @relation = relation
        @column = column
        @period = period
        @time_zone = time_zone
        @time_range = time_range
        @week_start = week_start
        @day_start = day_start
        @n_seconds = n_seconds
        @adapter_name = adapter_name
        @timezone_aware_column = timezone_aware_column

        # Only require UTC default_timezone for non-timezone-aware columns
        # Timezone-aware columns (like timestamptz in PostgreSQL) store timezone
        # information and work correctly regardless of default_timezone setting
        if ActiveRecord.default_timezone == :local && !timezone_aware_column
          raise Groupdate::Error, "ActiveRecord.default_timezone must be :utc to use Groupdate, or use a timezone-aware column type like timestamp with time zone (PostgreSQL)"
        end
      end

      def generate
        @relation.group(group_clause).where(*where_clause)
      end

      private

      def where_clause
        if @time_range.is_a?(Range)
          if @time_range.end
            op = @time_range.exclude_end? ? "<" : "<="
            if @time_range.begin
              ["#{column} >= ? AND #{column} #{op} ?", @time_range.begin, @time_range.end]
            else
              ["#{column} #{op} ?", @time_range.end]
            end
          else
            ["#{column} >= ?", @time_range.begin]
          end
        else
          ["#{column} IS NOT NULL"]
        end
      end
    end
  end
end
