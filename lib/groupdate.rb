require "active_support/time"
require "groupdate/version"
require "groupdate/magic"
begin
  require "active_record"
rescue LoadError
  # do nothing
end
require "groupdate/active_record" if defined?(ActiveRecord)
require "groupdate/enumerable"

module Groupdate
  mattr_accessor :week_start, :day_start, :time_zone
  self.week_start = :sun
  self.day_start = 0
end
