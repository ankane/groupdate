require "active_support/time"
require "groupdate/version"
require "groupdate/enumerable"
require "groupdate/active_record"

module Groupdate
  mattr_accessor :week_start, :day_start, :time_zone
  self.week_start = :sun
  self.day_start = 0
end
