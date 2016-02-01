require "active_record"
require "groupdate/order_hack"
require "groupdate/scopes"
require "groupdate/series"

ActiveRecord::Base.send(:extend, Groupdate::Scopes)

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
module ActiveRecord
  module Calculations
    private

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
