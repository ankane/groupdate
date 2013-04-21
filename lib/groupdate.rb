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
      trunc_fields = %w(microseconds milliseconds second minute hour day week month quarter year decade century millennium)
      extract_fields = %w(century day decade dow doy microseconds millennium milliseconds minute month quarter second week year hour)

      [[trunc_fields, true],[extract_fields, false]].each do |fields, trunc|
        fields.each do |field|
          self.scope :"group_by_#{field}#{trunc ? "" : "_part"}", lambda {|column, time_zone = Time.zone|
            time_zone ||= "Etc/UTC"
            if time_zone.is_a?(ActiveSupport::TimeZone) or time_zone = ActiveSupport::TimeZone[time_zone]
              time_zone = time_zone.tzinfo.name
            else
              raise "Unrecognized time zone"
            end
            query =
              if trunc
                sanitize_sql_array(["DATE_TRUNC('#{field}', #{column}::timestamptz AT TIME ZONE ?) AT TIME ZONE ?", time_zone, time_zone])
              else
                sanitize_sql_array(["EXTRACT(#{field.upcase} from #{column}::timestamptz AT TIME ZONE ?)", time_zone])
              end
            group(query)
          }
        end
      end
    end
  end

end

ActiveRecord::Base.send :include, Groupdate
