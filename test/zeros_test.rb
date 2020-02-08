require_relative "test_helper"

class ZerosTest < Minitest::Test
  def test_zeros_second
    assert_zeros :second, "2013-05-01 00:00:01 UTC", ["2013-05-01 00:00:00 UTC", "2013-05-01 00:00:01 UTC", "2013-05-01 00:00:02 UTC"], "2013-05-01 00:00:00.999 UTC", "2013-05-01 00:00:02 UTC"
  end

  def test_zeros_minute
    assert_zeros :minute, "2013-05-01 00:01:00 UTC", ["2013-05-01 00:00:00 UTC", "2013-05-01 00:01:00 UTC", "2013-05-01 00:02:00 UTC"], "2013-05-01 00:00:59 UTC", "2013-05-01 00:02:00 UTC"
  end

  def test_zeros_hour
    assert_zeros :hour, "2013-05-01 04:01:01 UTC", ["2013-05-01 03:00:00 UTC", "2013-05-01 04:00:00 UTC", "2013-05-01 05:00:00 UTC"], "2013-05-01 03:59:59 UTC", "2013-05-01 05:00:00 UTC"
  end

  def test_zeros_day
    assert_zeros_date :day, "2013-05-01 20:00:00 UTC", ["2013-04-30", "2013-05-01", "2013-05-02"], "2013-04-30 00:00:00 UTC", "2013-05-02 23:59:59 UTC"
  end

  def test_zeros_day_time_zone
    assert_zeros_date :day, "2013-05-01 20:00:00 PDT", ["2013-04-30", "2013-05-01", "2013-05-02"], "2013-04-30 00:00:00 PDT", "2013-05-02 23:59:59 PDT", true
  end

  def test_zeros_week
    assert_zeros_date :week, "2013-05-01 20:00:00 UTC", ["2013-04-21", "2013-04-28", "2013-05-05"], "2013-04-27 23:59:59 UTC", "2013-05-11 23:59:59 UTC"
  end

  def test_zeros_week_time_zone
    assert_zeros_date :week, "2013-05-01 20:00:00 PDT", ["2013-04-21", "2013-04-28", "2013-05-05"], "2013-04-27 23:59:59 PDT", "2013-05-11 23:59:59 PDT", true
  end

  def test_zeros_week_mon
    assert_zeros_date :week, "2013-05-01 20:00:00 UTC", ["2013-04-22", "2013-04-29", "2013-05-06"], "2013-04-27 23:59:59 UTC", "2013-05-11 23:59:59 UTC", false, week_start: :mon
  end

  def test_zeros_week_time_zone_mon
    assert_zeros_date :week, "2013-05-01 20:00:00 PDT", ["2013-04-22", "2013-04-29", "2013-05-06"], "2013-04-27 23:59:59 PDT", "2013-05-11 23:59:59 PDT", true, week_start: :mon
  end

  def test_zeros_week_sat
    assert_zeros_date :week, "2013-05-01 20:00:00 UTC", ["2013-04-20", "2013-04-27", "2013-05-04"], "2013-04-26 23:59:59 UTC", "2013-05-10 23:59:59 UTC", false, week_start: :sat
  end

  def test_zeros_week_time_zone_sat
    assert_zeros_date :week, "2013-05-01 20:00:00 PDT", ["2013-04-20", "2013-04-27", "2013-05-04"], "2013-04-26 23:59:59 PDT", "2013-05-10 23:59:59 PDT", true, week_start: :sat
  end

  def test_zeros_month
    assert_zeros_date :month, "2013-04-16 20:00:00 UTC", ["2013-03-01", "2013-04-01", "2013-05-01"], "2013-03-01", "2013-05-31 23:59:59 UTC"
  end

  def test_zeros_month_time_zone
    assert_zeros_date :month, "2013-04-16 20:00:00 PDT", ["2013-03-01", "2013-04-01", "2013-05-01"], "2013-03-01 00:00:00 PST", "2013-05-31 23:59:59 PDT", true
  end

  def test_zeros_quarter
    assert_zeros_date :quarter, "2013-04-16 20:00:00 UTC", ["2013-01-01", "2013-04-01", "2013-07-01"], "2013-01-01", "2013-09-30 23:59:59 UTC"
  end

  def test_zeros_quarter_time_zone
    assert_zeros_date :quarter, "2013-04-16 20:00:00 PDT", ["2013-01-01", "2013-04-01", "2013-07-01"], "2013-01-01 00:00:00 PST", "2013-09-30 23:59:59 PDT", true
  end

  def test_zeros_year
    assert_zeros_date :year, "2013-04-16 20:00:00 UTC", ["2012-01-01", "2013-01-01", "2014-01-01"], "2012-01-01", "2014-12-31 23:59:59 UTC"
  end

  def test_zeros_year_time_zone
    assert_zeros_date :year, "2013-04-16 20:00:00 PDT", ["2012-01-01 00:00:00 PST", "2013-01-01 00:00:00 PST", "2014-01-01 00:00:00 PST"], "2012-01-01 00:00:00 PST", "2014-12-31 23:59:59 PST", true
  end

  def test_zeros_day_of_week
    create_user "2013-05-01"
    expected = {}
    7.times do |n|
      expected[n] = n == 3 ? 1 : 0
    end
    assert_equal expected, call_method(:day_of_week, :created_at, {series: true})
  end

  def test_zeros_hour_of_day
    create_user "2013-05-01 20:00:00 UTC"
    expected = {}
    24.times do |n|
      expected[n] = n == 20 ? 1 : 0
    end
    assert_equal expected, call_method(:hour_of_day, :created_at, {series: true})
  end

  def test_zeros_minute_of_hour
    create_user "2017-02-09 20:05:00 UTC"
    expected = {}
    60.times do |n|
      expected[n] = n == 5 ? 1 : 0
    end
    assert_equal expected, call_method(:minute_of_hour, :created_at, {series: true})
  end

  def test_zeros_day_of_month
    create_user "1978-12-18"
    expected = {}
    (1..31).each do |n|
      expected[n] = n == 18 ? 1 : 0
    end
    assert_equal expected, call_method(:day_of_month, :created_at, {series: true})
  end

  def test_zeros_month_of_year
    create_user "2013-05-01"
    expected = {}
    (1..12).each do |n|
      expected[n] = n == 5 ? 1 : 0
    end
    assert_equal expected, call_method(:month_of_year, :created_at, {series: true})
  end

  def test_zeros_excludes_end
    create_user "2013-05-02"
    expected = {
      Date.parse("2013-05-01") => 0
    }
    assert_equal expected, call_method(:day, :created_at, range: Date.parse("2013-05-01")...Date.parse("2013-05-02"), series: true)
  end

  def test_zeros_datetime
    # flaky
    skip if sqlite?

    create_user "2013-05-01"
    expected = {
      Date.parse("2013-05-01") => 1
    }
    assert_equal expected, call_method(:day, :created_at, range: DateTime.parse("2013-05-01")..DateTime.parse("2013-05-01"), series: true)
  end

  def test_zeroes_range_true
    create_user "2013-05-01"
    create_user "2013-05-03"
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, call_method(:day, :created_at, range: true, series: true)
  end

  def assert_zeros(method, created_at, keys, range_start, range_end, time_zone = nil, options = {})
    create_user created_at
    expected = {}
    keys.each_with_index do |key, i|
      expected[utc.parse(key).in_time_zone(time_zone ? "Pacific Time (US & Canada)" : utc)] = i == 1 ? 1 : 0
    end
    assert_equal expected, call_method(method, :created_at, options.merge(series: true, time_zone: time_zone ? "Pacific Time (US & Canada)" : nil, range: Time.parse(range_start)..Time.parse(range_end)))
  end

  def assert_zeros_date(method, created_at, keys, range_start, range_end, time_zone = nil, options = {})
    create_user created_at
    expected = {}
    keys.each_with_index do |key, i|
      expected[Date.parse(key)] = i == 1 ? 1 : 0
    end
    assert_equal expected, call_method(method, :created_at, options.merge(series: true, time_zone: time_zone ? "Pacific Time (US & Canada)" : nil, range: Time.parse(range_start)..Time.parse(range_end)))
  end
end
