require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "logger"
require "active_record"
require "ostruct"

ENV["TZ"] = "UTC"

adapter = ENV["ADAPTER"]
abort "No adapter specified" unless adapter

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
    if enumerable?
      @users = []
    else
      User.delete_all
    end
  end

  def sqlite?
    ENV["ADAPTER"] == "sqlite"
  end

  def enumerable?
    ENV["ADAPTER"] == "enumerable"
  end

  def postgresql?
    ENV["ADAPTER"] == "postgresql"
  end

  def create_user(created_at, score = 1)
    created_at = created_at.utc.to_s if created_at.is_a?(Time)

    if enumerable?
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
        User.new(
          name: "Andrew",
          score: score,
          created_at: created_at ? utc.parse(created_at) : nil,
          created_on: created_at ? Date.parse(created_at) : nil
        )

      if postgresql?
        user.deleted_at = user.created_at
      end

      user.save!

      # hack for Redshift adapter, which doesn't return id on creation...
      user = User.last if user.id.nil?

      user.update_columns(created_at: nil, created_on: nil) if created_at.nil?
    end

    user
  end

  def call_method(method, field, options)
    if enumerable?
      Hash[@users.group_by_period(method, **options) { |u| u.send(field) }.map { |k, v| [k, v.size] }]
    elsif sqlite? && (method == :quarter || options[:time_zone] || options[:day_start] || (Time.zone && options[:time_zone] != false))
      error = assert_raises(Groupdate::Error) { User.group_by_period(method, field, **options).count }
      assert_includes error.message, "not supported for SQLite"
      skip
    else
      if options[:series_label].present?
        User.select('COUNT(*) AS count').group_by_period(method, field, options).map do |r|
          [r.send(options[:series_label]), r.count]
        end.to_h
      else
        User.group_by_period(method, field, **options).count
      end
    end
  end

  def assert_result_time(method, expected, time_str, time_zone = false, options = {})
    create_user time_str
    expected = {utc.parse(expected).in_time_zone(time_zone ? "Pacific Time (US & Canada)" : utc) => 1}
    assert_equal expected, result(method, time_str, time_zone, :created_at, options)
    assert_equal expected, result(method, time_str, time_zone, :created_at, options.merge(series_label: :label))

    if postgresql?
      # test timestamptz
      assert_equal expected, result(method, time_str, time_zone, :deleted_at, options)
      assert_equal expected, result(method, time_str, time_zone, :deleted_at, options.merge(series_label: :label))
    end
  end

  def assert_result_date(method, expected_str, time_str, time_zone = false, options = {})
    create_user time_str
    expected = {Date.parse(expected_str) => 1}

    options.merge!(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil)
    label_options = options.merge(series_label: :label)

    assert_equal expected, call_method(method, :created_at, options)
    assert_equal expected, call_method(method, :created_at, label_options)

    expected_time = (time_zone ? pt : utc).parse(expected_str)
    if options[:day_start]
      expected_time = expected_time.change(hour: options[:day_start], min: (options[:day_start] % 1) * 60)
    end
    expected = {expected_time => 1}
    
    assert_equal expected, call_method(method, :created_at, options.merge(dates: false))
    assert_equal expected, call_method(method, :created_at, label_options.merge(dates: false))
    # assert_equal expected, call_method(method, :created_on, options.merge(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil))
  end

  def assert_result(method, expected, time_str, time_zone = false, options = {})
    create_user time_str
    assert_equal 1, result(method, time_str, time_zone, :created_at, options)[expected]
    assert_equal 1, result(method, time_str, time_zone, :created_at, options.merge(series_label: :label))[expected]
  end

  def result(method, time_str, time_zone = false, attribute = :created_at, options = {})
    call_method(method, attribute, options.merge(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil))
  end

  def utc
    ActiveSupport::TimeZone["UTC"]
  end

  def pt
    ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
  end
end
