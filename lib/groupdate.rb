require "active_support/core_ext/module/attribute_accessors"
require "active_support/time"
require "groupdate/version"
require "groupdate/magic"

module Groupdate
  FIELDS = [:second, :minute, :hour, :day, :week, :month, :year, :day_of_week, :hour_of_day, :day_of_month, :month_of_year]
  METHODS = FIELDS.map { |v| :"group_by_#{v}" }

  mattr_accessor :week_start, :day_start, :time_zone
  self.week_start = :sun
  self.day_start = 0
end

require "groupdate/enumerable"
begin
  require "active_record"
rescue LoadError
  # do nothing
end
require "groupdate/active_record" if defined?(ActiveRecord)
