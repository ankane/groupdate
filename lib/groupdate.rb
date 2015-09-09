unless defined?(ActiveSupport)
  require "active_support/time"
  require "active_support/core_ext/module/attribute_accessors"
end
require "groupdate/version"
require "groupdate/magic"

module Groupdate
  FIELDS = [:second, :minute, :hour, :day, :week, :month, :year, :day_of_week, :hour_of_day, :day_of_month, :month_of_year].freeze
  METHODS = FIELDS.map { |v| :"group_by_#{v}" }.freeze

  mattr_accessor :week_start, :day_start, :time_zone
  self.week_start = :sun
  self.day_start = 0
end

require "groupdate/enumerable"
begin
  require "active_record" unless defined?(ActiveRecord)
rescue LoadError
  # do nothing
end
require "groupdate/active_record" if defined?(ActiveRecord)
