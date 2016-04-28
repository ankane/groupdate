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
        delegate(*Groupdate::METHODS, to: :scoped)
      end
    end
  end
end

# hack for issue before Rails 5
# https://github.com/rails/rails/issues/7121
module ActiveRecord
  module Calculations
    private

    if ActiveRecord::VERSION::MAJOR < 5
      def column_alias_for_with_hack(*keys)
        if keys.first.is_a?(Groupdate::OrderHack)
          keys.first.field
        else
          column_alias_for_without_hack(*keys)
        end
      end
      alias_method_chain :column_alias_for, :hack
    end
  end
end
