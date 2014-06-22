require "groupdate/order_hack"
require "groupdate/series"
require "active_record"

module Groupdate
  module Scopes

    [:second, :minute, :hour, :day, :week, :month, :year, :day_of_week, :hour_of_day].each do |field|
      define_method :"group_by_#{field}" do |*args|
        args = args.dup
        options = args[-1].is_a?(Hash) ? args.pop : {}
        options[:time_zone] ||= args[1] unless args[1].nil?
        options[:range] ||= args[2] unless args[2].nil?

        Groupdate::Magic.new(field, options).relation(args[0], self)
      end
    end

  end
end
