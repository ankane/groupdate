require "groupdate/version"

module Groupdate
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
      %w(microseconds milliseconds second minute hour day week month quarter year decade century millennium).each do |field|
        self.scope :"group_by_#{field}", lambda {|column, time_zone = Time.zone|
          time_zone ||= "Etc/UTC"
          if time_zone.is_a?(ActiveSupport::TimeZone) or time_zone = ActiveSupport::TimeZone[time_zone]
            time_zone = time_zone.tzinfo.name
          else
            raise "Unrecognized time zone"
          end
          sql = "DATE_TRUNC('#{field}', #{column}::timestamptz AT TIME ZONE ?) AT TIME ZONE ?"
          group(sanitize_sql_array([sql, time_zone, time_zone]))
        }
      end
    end
  end

end

ActiveRecord::Base.send :include, Groupdate
