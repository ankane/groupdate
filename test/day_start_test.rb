require_relative "test_helper"

class DayStartTest < Minitest::Test
  # second not affected

  def test_second_end_of_second
    assert_result_time :second, "2013-05-03 00:00:00 UTC", "2013-05-03 00:00:00.999", false, day_start: 2
  end

  def test_second_start_of_second
    assert_result_time :second, "2013-05-03 00:00:01 UTC", "2013-05-03 00:00:01.000", false, day_start: 2
  end

  # minute not affected

  def test_minute_end_of_minute
    assert_result_time :minute, "2013-05-03 00:00:00 UTC", "2013-05-03 00:00:59", false, day_start: 2
  end

  def test_minute_start_of_minute
    assert_result_time :minute, "2013-05-03 00:01:00 UTC", "2013-05-03 00:01:00", false, day_start: 2
  end

  # day hour starts at 2 am

  def test_day_end_of_day
    assert_result_date :day, "2013-05-03", "2013-05-04 01:59:59", false, day_start: 2
  end

  def test_day_start_of_day
    assert_result_date :day, "2013-05-03", "2013-05-03 02:00:00", false, day_start: 2
  end

  def test_day_end_of_day_with_time_zone
    assert_result_date :day, "2013-05-03", "2013-05-04 07:59:59", true, day_start: 2
  end

  def test_day_start_of_day_with_time_zone
    assert_result_date :day, "2013-05-03", "2013-05-03 09:00:00", true, day_start: 2
  end

  # week starting at 2am

  def test_week_end_of_week
    assert_result_date :week, "2013-03-17", "2013-03-24 01:59:59", false, day_start: 2
  end

  def test_week_start_of_week
    assert_result_date :week, "2013-03-17", "2013-03-17 02:00:00", false, day_start: 2
  end

  def test_week_end_of_week_with_time_zone
    assert_result_date :week, "2013-03-17", "2013-03-24 08:59:59", true, day_start: 2
  end

  def test_week_start_of_week_with_time_zone
    assert_result_date :week, "2013-03-17", "2013-03-17 09:00:00", true, day_start: 2
  end

  # month starts at 2am

  def test_month_end_of_month
    assert_result_date :month, "2013-03-01", "2013-04-01 01:59:59", false, day_start: 2
  end

  def test_month_start_of_month
    assert_result_date :month, "2013-03-01", "2013-03-01 02:00:00", false, day_start: 2
  end

  def test_month_end_of_month_with_time_zone
    assert_result_date :month, "2013-03-01", "2013-04-01 08:59:59", true, day_start: 2
  end

  def test_month_start_of_month_with_time_zone
    assert_result_date :month, "2013-03-01", "2013-03-01 10:00:00", true, day_start: 2
  end

  # quarter starts at 2am

  def test_quarter_end_of_quarter
    assert_result_date :quarter, "2013-04-01", "2013-07-01 01:59:59", false, day_start: 2
  end

  def test_quarter_start_of_quarter
    assert_result_date :quarter, "2013-04-01", "2013-04-01 02:00:00", false, day_start: 2
  end

  def test_quarter_end_of_quarter_with_time_zone
    assert_result_date :quarter, "2013-01-01", "2013-04-01 08:59:59", true, day_start: 2
  end

  def test_quarter_start_of_quarter_with_time_zone
    assert_result_date :quarter, "2013-01-01", "2013-01-01 10:00:00", true, day_start: 2
  end

  # year starts at 2am

  def test_year_end_of_year
    assert_result_date :year, "2013-01-01", "2014-01-01 01:59:59", false, day_start: 2
  end

  def test_year_start_of_year
    assert_result_date :year, "2013-01-01", "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_year_end_of_year_with_time_zone
    assert_result_date :year, "2013-01-01", "2014-01-01 09:59:59", true, day_start: 2
  end

  def test_year_start_of_year_with_time_zone
    assert_result_date :year, "2013-01-01", "2013-01-01 10:00:00", true, day_start: 2
  end

  # hour of day starts at 2am

  def test_hour_of_day_end_of_day
    assert_result :hour_of_day, 23, "2013-01-01 01:59:59", false, day_start: 2
  end

  def test_hour_of_day_start_of_day
    assert_result :hour_of_day, 0, "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_hour_of_day_end_of_day_with_time_zone
    assert_result :hour_of_day, 23, "2013-01-01 09:59:59", true, day_start: 2
  end

  def test_hour_of_day_start_of_day_with_time_zone
    assert_result :hour_of_day, 0, "2013-01-01 10:00:00", true, day_start: 2
  end

  # day of week starts at 2am

  def test_day_of_week_end_of_day
    assert_result :day_of_week, 3, "2013-01-03 01:59:59", false, day_start: 2
  end

  def test_day_of_week_start_of_day
    assert_result :day_of_week, 3, "2013-01-02 02:00:00", false, day_start: 2
  end

  def test_day_of_week_end_of_day_with_time_zone
    assert_result :day_of_week, 3, "2013-01-03 09:59:59", true, day_start: 2
  end

  def test_day_of_week_start_of_day_with_time_zone
    assert_result :day_of_week, 3, "2013-01-02 10:00:00", true, day_start: 2
  end

  # day of month starts at 2am

  def test_day_of_month_end_of_day
    assert_result :day_of_month, 31, "2013-01-01 01:59:59", false, day_start: 2
  end

  def test_day_of_month_start_of_day
    assert_result :day_of_month, 1, "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_day_of_month_end_of_day_with_time_zone
    assert_result :day_of_month, 31, "2013-01-01 09:59:59", true, day_start: 2
  end

  def test_day_of_month_start_of_day_with_time_zone
    assert_result :day_of_month, 1, "2013-01-01 10:00:00", true, day_start: 2
  end

  # month of year starts at 2am

  def test_month_of_year_end_of_month
    assert_result :month_of_year, 12, "2013-01-01 01:59:59", false, day_start: 2
  end

  def test_month_of_year_start_of_month
    assert_result :month_of_year, 1, "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_month_of_year_end_of_month_with_time_zone
    assert_result :month_of_year, 12, "2013-01-01 09:59:59", true, day_start: 2
  end

  def test_month_of_year_start_of_month_with_time_zone
    assert_result :month_of_year, 1, "2013-01-01 10:00:00", true, day_start: 2
  end

  # decimal

  def test_decimal_end_of_day
    assert_result_date :day, "2013-05-03", "2013-05-04 02:29:59", false, day_start: 2.5
  end

  def test_decimal_start_of_day
    assert_result_date :day, "2013-05-03", "2013-05-03 02:30:00", false, day_start: 2.5
  end

  def test_decimal_hour_of_day
    skip if sqlite?
    assert_result :hour_of_day, 23, "2013-05-04 02:29:59", false, day_start: 2.5
  end

  # invalid

  def test_too_small
    # TODO raise error
    call_method(:day, :created_at, day_start: -1)
  end

  def test_too_large
    # TODO raise error
    call_method(:day, :created_at, day_start: 24)
  end

  # dst behavior

  def test_dst_day_spring
    # TODO make consistent
    expected = ENV["ADAPTER"] == "enumerable" ? "2013-03-09" : "2013-03-10"

    time = pt.parse("2013-03-10 03:00:00")
    assert_result_date :day, expected, time, true, day_start: 3
  end

  def test_dst_week_spring
    # TODO make consistent
    expected = ENV["ADAPTER"] == "enumerable" ? "2013-03-03" : "2013-03-10"

    time = pt.parse("2013-03-10 03:00:00")
    assert_result_date :week, expected, time, true, day_start: 3
  end

  def test_dst_hour_of_day_spring
    # TODO make consistent
    expected = ENV["ADAPTER"] == "enumerable" ? 23 : 0

    time = pt.parse("2013-03-10 03:00:00")
    assert_result :hour_of_day, expected, time, true, day_start: 3
  end

  def test_dst_hour_of_day_fall
    # TODO make consistent
    expected = ENV["ADAPTER"] == "enumerable" ? 1 : 0

    time = pt.parse("2013-11-03 01:00:00") + 1.hour # second 1 am of the day
    assert_result :hour_of_day, expected, time, true, day_start: 1
  end

  def test_dst_dates_false
    skip

    ["2013-03-09", "2013-03-10", "2013-03-11"].each do |week|
      create_user pt.parse(week)
    end
    results = call_method(:day, :created_at, day_start: 3, dates: false, time_zone: pt)
    assert_equal [3, 3, 3], results.keys.map(&:hour)
  end
end
