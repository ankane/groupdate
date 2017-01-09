require "active_support/core_ext/module/attribute_accessors"
require "active_support/time"
require "groupdate/version"
require "groupdate/magic"

module Groupdate
  class Error < RuntimeError; end

  PERIODS = [:second, :minute, :hour, :day, :week, :month, :quarter, :year, :day_of_week, :hour_of_day, :day_of_month, :month_of_year]
  # backwards compatibility for anyone who happened to use it
  FIELDS = PERIODS
  METHODS = PERIODS.map { |v| :"group_by_#{v}" } + [:group_by_period]

  mattr_accessor :week_start, :day_start, :time_zone, :dates
  self.week_start = :sun
  self.day_start = 0
  self.dates = true
end

require "groupdate/enumerable"

ActiveSupport.on_load(:active_record) do
  require "groupdate/active_record"
end
