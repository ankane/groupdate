module Groupdate
  module Adapters
    class BaseAdapter
      attr_reader :period, :column, :day_start, :week_start, :n_seconds

      def initialize(relation, column:, period:, time_zone:, time_range:, week_start:, day_start:, n_seconds:)
        # very important
        column = validate_column(column)

        @relation = relation
        @column = resolve_column(relation, column)
        @period = period
        @time_zone = time_zone
        @time_range = time_range
        @week_start = week_start
        @day_start = day_start
        @n_seconds = n_seconds

        if relation.default_timezone == :local
          raise Groupdate::Error, "ActiveRecord::Base.default_timezone must be :utc to use Groupdate"
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

      # basic version of Active Record disallow_raw_sql!
      # symbol = column (safe), Arel node = SQL (safe), other = untrusted
      # matches table.column and column
      def validate_column(column)
        unless column.is_a?(Symbol) || column.is_a?(Arel::Nodes::SqlLiteral)
          column = column.to_s
          unless /\A\w+(\.\w+)?\z/i.match(column)
            warn "[groupdate] Non-attribute argument: #{column}. Use Arel.sql() for known-safe values. This will raise an error in Groupdate 6"
          end
        end
        column
      end

      # resolves eagerly
      # need to convert both where_clause (easy)
      # and group_clause (not easy) if want to avoid this
      def resolve_column(relation, column)
        node = relation.send(:relation).send(:arel_columns, [column]).first
        node = Arel::Nodes::SqlLiteral.new(node) if node.is_a?(String)
        relation.connection.visitor.accept(node, Arel::Collectors::SQLString.new).value
      end
    end
  end
end
