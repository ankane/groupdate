require "active_support/core_ext/module/attribute_accessors"
require "active_support/time"
require "groupdate/version"
require "groupdate/magic"

module Groupdate
  PERIODS = [:second, :minute, :hour, :day, :week, :month, :quarter, :year,
             :day_of_week, :hour_of_day, :day_of_month, :month_of_year, :time_range]
  # backwards compatibility for anyone who happened to use it
  FIELDS = PERIODS
  METHODS = PERIODS.map { |v| :"group_by_#{v}" } + [:group_by_period]

  mattr_accessor :week_start, :day_start, :time_zone, :database_time_zone, :dates
  self.week_start = :sun
  self.day_start = 0
  self.dates = true
end

require "groupdate/enumerable"

ActiveSupport.on_load(:active_record) do
  require "groupdate/active_record"
end
