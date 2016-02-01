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
