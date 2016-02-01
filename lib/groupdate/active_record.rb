require "active_record"
require "groupdate/order_hack"
require "groupdate/scopes"
require "groupdate/series"

ActiveRecord::Base.send(:extend, Groupdate::Scopes)

module ActiveRecord
  class Relation
    if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR < 2

      def method_missing_with_hack(method, *args, &block)
        if Groupdate::METHODS.include?(method)
          scoping { @klass.send(method, *args, &block) }
        else
          method_missing_without_hack(method, *args, &block)
        end
      end
      alias_method_chain :method_missing, :hack

    end
  end
end

module ActiveRecord
  module Associations
    class CollectionProxy
      if ActiveRecord::VERSION::MAJOR == 3
        delegate *Groupdate::METHODS, to: :scoped
      end
    end
  end
end

# hack for **unfixed** rails issue
# https://github.com/rails/rails/issues/7121
module Groupdate
  module Calculations
    def column_alias_for(*keys)
      if keys.first.is_a?(Groupdate::OrderHack)
        keys.first.field
      else
        super
      end
    end
  end
end

ActiveRecord::Calculations.prepend(Groupdate::Calculations)
