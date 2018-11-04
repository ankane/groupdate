require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "logger"
require "active_record"
require "ostruct"

ENV["TZ"] = "UTC"

adapter = ENV["ADAPTER"]
puts "Using #{adapter}"
require_relative "adapters/#{adapter}"

require_relative "support/activerecord" unless adapter == "enumerable"

# i18n
I18n.enforce_available_locales = true
I18n.backend.store_translations :de, date: {
  abbr_month_names: %w(Jan Feb Mar Apr Mai Jun Jul Aug Sep Okt Nov Dez).unshift(nil)
},
time: {
  formats: {special: "%b %e, %Y"}
}

class Minitest::Test
  def setup
    if ENV["ADAPTER"] == "enumerable"
      @users = []
    else
      User.delete_all
    end
  end

  def create_user(created_at, score = 1)
    if ENV["ADAPTER"] == "enumerable"
      user =
        OpenStruct.new(
          name: "Andrew",
          score: score,
          created_at: created_at ? utc.parse(created_at) : nil,
          created_on: created_at ? Date.parse(created_at) : nil
        )
      @users << user
    else
      user =
        User.create!(
          name: "Andrew",
          score: score,
          created_at: created_at ? utc.parse(created_at) : nil,
          created_on: created_at ? Date.parse(created_at) : nil
        )

      # hack for Redshift adapter, which doesn't return id on creation...
      user = User.last if user.id.nil?

      user.update_columns(created_at: nil, created_on: nil) if created_at.nil?
    end

    user
  end

  def utc
    ActiveSupport::TimeZone["UTC"]
  end

  def call_method(method, field, options)
    if ENV["ADAPTER"] == "enumerable"
      Hash[@users.group_by_period(method, options) { |u| u.send(field) }.map { |k, v| [k, v.size] }]
    elsif ENV["ADAPTER"] == "sqlite" && (method == :quarter || options[:time_zone] || options[:day_start] || options[:week_start] || Groupdate.week_start != :sun || (Time.zone && options[:time_zone] != false))
      error = assert_raises(Groupdate::Error) { User.group_by_period(method, field, options).count }
      assert_includes error.message, "not supported for SQLite"
      skip
    else
      User.group_by_period(method, field, options).count
    end
  end

  def assert_format(method, expected, format, options = {})
    assert_equal({expected => 1}, call_method(method, :created_at, options.merge(format: format, series: false)))
  end

  def assert_result_time(method, expected, time_str, time_zone = false, options = {})
    expected = {utc.parse(expected).in_time_zone(time_zone ? "Pacific Time (US & Canada)" : utc) => 1}
    assert_equal expected, result(method, time_str, time_zone, options)
  end

  def assert_result_date(method, expected_str, time_str, time_zone = false, options = {})
    create_user time_str
    expected = {Date.parse(expected_str) => 1}
    assert_equal expected, call_method(method, :created_at, options.merge(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil))
    expected = {(time_zone ? pt : utc).parse(expected_str) + options[:day_start].to_f.hours => 1}
    assert_equal expected, call_method(method, :created_at, options.merge(dates: false, time_zone: time_zone ? "Pacific Time (US & Canada)" : nil))
    # assert_equal expected, call_method(method, :created_on, options.merge(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil))
  end

  def assert_result(method, expected, time_str, time_zone = false, options = {})
    assert_equal 1, result(method, time_str, time_zone, options)[expected]
  end

  def result(method, time_str, time_zone = false, options = {})
    create_user time_str
    call_method(method, :created_at, options.merge(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil))
  end

  def pt
    ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
  end
end
