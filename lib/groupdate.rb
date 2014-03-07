require "groupdate/version"
require "groupdate/scopes"

ActiveRecord::Base.send :extend, Groupdate::Scopes

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

module Groupdate
  mattr_accessor :week_start, :day_start, :time_zone
  self.week_start = :sun
  self.day_start = 0
end
