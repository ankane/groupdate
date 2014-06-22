require "active_support/time"
require "groupdate/version"
require "groupdate/magic"
require "groupdate/active_record"
require "groupdate/enumerable"

module Groupdate
  mattr_accessor :week_start, :day_start, :time_zone
  self.week_start = :sun
  self.day_start = 0
end
