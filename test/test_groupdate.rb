module TestGroupdate
  def setup
    Groupdate.week_start = :sun
  end

  # second

  def test_second_end_of_second
    if enumerable_test? || ActiveRecord::Base.connection.adapter_name == "Mysql2"
      skip # no millisecond precision
    else
      assert_result_time :second, "2013-05-03 00:00:00 UTC", "2013-05-03 00:00:00.999"
    end
  end

  def test_second_start_of_second
    assert_result_time :second, "2013-05-03 00:00:01 UTC", "2013-05-03 00:00:01.000"
  end

  # minute

  def test_minute_end_of_minute
    assert_result_time :minute, "2013-05-03 00:00:00 UTC", "2013-05-03 00:00:59"
  end

  def test_minute_start_of_minute
    assert_result_time :minute, "2013-05-03 00:01:00 UTC", "2013-05-03 00:01:00"
  end

  # hour

  def test_hour_end_of_hour
    assert_result_time :hour, "2013-05-03 00:00:00 UTC", "2013-05-03 00:59:59"
  end

  def test_hour_start_of_hour
    assert_result_time :hour, "2013-05-03 01:00:00 UTC", "2013-05-03 01:00:00"
  end

  # day

  def test_day_end_of_day
    assert_result_date :day, "2013-05-03", "2013-05-03 23:59:59"
  end

  def test_day_start_of_day
    assert_result_date :day, "2013-05-04", "2013-05-04 00:00:00"
  end

  def test_day_end_of_day_with_time_zone
    assert_result_date :day, "2013-05-02", "2013-05-03 06:59:59", true
  end

  def test_day_start_of_day_with_time_zone
    assert_result_date :day, "2013-05-03", "2013-05-03 07:00:00", true
  end

  # day hour starts at 2 am

  def test_test_day_end_of_day_day_start_2am
    assert_result_date :day, "2013-05-03", "2013-05-04 01:59:59", false, day_start: 2
  end

  def test_test_day_start_of_day_day_start_2am
    assert_result_date :day, "2013-05-03", "2013-05-03 02:00:00", false, day_start: 2
  end

  def test_test_day_end_of_day_with_time_zone_day_start_2am
    assert_result_date :day, "2013-05-03", "2013-05-04 07:59:59", true, day_start: 2
  end

  def test_test_day_start_of_day_with_time_zone_day_start_2am
    assert_result_date :day, "2013-05-03", "2013-05-03 09:00:00", true, day_start: 2
  end

  # week

  def test_week_end_of_week
    assert_result_date :week, "2013-03-17", "2013-03-23 23:59:59"
  end

  def test_week_start_of_week
    assert_result_date :week, "2013-03-24", "2013-03-24 00:00:00"
  end

  def test_week_end_of_week_with_time_zone
    assert_result_date :week, "2013-03-10", "2013-03-17 06:59:59", true
  end

  def test_week_start_of_week_with_time_zone
    assert_result_date :week, "2013-03-17", "2013-03-17 07:00:00", true
  end

  # week starting on monday

  def test_week_end_of_week_mon
    assert_result_date :week, "2013-03-18", "2013-03-24 23:59:59", false, week_start: :mon
  end

  def test_week_start_of_week_mon
    assert_result_date :week, "2013-03-25", "2013-03-25 00:00:00", false, week_start: :mon
  end

  def test_week_end_of_week_with_time_zone_mon
    assert_result_date :week, "2013-03-11", "2013-03-18 06:59:59", true, week_start: :mon
  end

  def test_week_start_of_week_with_time_zone_mon
    assert_result_date :week, "2013-03-18", "2013-03-18 07:00:00", true, week_start: :mon
  end

  # week starting on saturday

  def test_week_end_of_week_sat
    assert_result_date :week, "2013-03-16", "2013-03-22 23:59:59", false, week_start: :sat
  end

  def test_week_start_of_week_sat
    assert_result_date :week, "2013-03-23", "2013-03-23 00:00:00", false, week_start: :sat
  end

  def test_week_end_of_week_with_time_zone_sat
    assert_result_date :week, "2013-03-09", "2013-03-16 06:59:59", true, week_start: :sat
  end

  def test_week_start_of_week_with_time_zone_sat
    assert_result_date :week, "2013-03-16", "2013-03-16 07:00:00", true, week_start: :sat
  end

  # week starting at 2am

  def test_week_end_of_week_day_start_2am
    assert_result_date :week, "2013-03-17", "2013-03-24 01:59:59", false, day_start: 2
  end

  def test_week_start_of_week_day_start_2am
    assert_result_date :week, "2013-03-17", "2013-03-17 02:00:00", false, day_start: 2
  end

  def test_week_end_of_week_day_with_time_zone_start_2am
    assert_result_date :week, "2013-03-17", "2013-03-24 08:59:59", true, day_start: 2
  end

  def test_week_start_of_week_day_with_time_zone_start_2am
    assert_result_date :week, "2013-03-17", "2013-03-17 09:00:00", true, day_start: 2
  end

  # month

  def test_month_end_of_month
    assert_result_date :month, "2013-05-01", "2013-05-31 23:59:59"
  end

  def test_month_start_of_month
    assert_result_date :month, "2013-06-01", "2013-06-01 00:00:00"
  end

  def test_month_end_of_month_with_time_zone
    assert_result_date :month, "2013-05-01", "2013-06-01 06:59:59", true
  end

  def test_month_start_of_month_with_time_zone
    assert_result_date :month, "2013-06-01", "2013-06-01 07:00:00", true
  end

  # month starts at 2am

  def test_month_end_of_month_day_start_2am
    assert_result_date :month, "2013-03-01", "2013-04-01 01:59:59", false, day_start: 2
  end

  def test_month_start_of_month_day_start_2am
    assert_result_date :month, "2013-03-01", "2013-03-01 02:00:00", false, day_start: 2
  end

  def test_month_end_of_month_with_time_zone_day_start_2am
    assert_result_date :month, "2013-03-01", "2013-04-01 08:59:59", true, day_start: 2
  end

  def test_month_start_of_month_with_time_zone_day_start_2am
    assert_result_date :month, "2013-03-01", "2013-03-01 10:00:00", true, day_start: 2
  end

  # quarter

  def test_quarter_end_of_quarter
    assert_result_date :quarter, "2013-04-01", "2013-06-30 23:59:59"
  end

  def test_quarter_start_of_quarter
    assert_result_date :quarter, "2013-04-01", "2013-04-01 00:00:00"
  end

  def test_quarter_end_of_quarter_with_time_zone
    assert_result_date :quarter, "2013-04-01", "2013-07-01 06:59:59", true
  end

  def test_quarter_start_of_quarter_with_time_zone
    assert_result_date :quarter, "2013-04-01", "2013-04-01 07:00:00", true
  end

  # quarter starts at 2am

  def test_quarter_end_of_quarter_day_start_2am
    assert_result_date :quarter, "2013-04-01", "2013-07-01 01:59:59", false, day_start: 2
  end

  def test_quarter_start_of_quarter_day_start_2am
    assert_result_date :quarter, "2013-04-01", "2013-04-01 02:00:00", false, day_start: 2
  end

  def test_quarter_end_of_quarter_with_time_zone_day_start_2am
    assert_result_date :quarter, "2013-01-01", "2013-04-01 08:59:59", true, day_start: 2
  end

  def test_quarter_start_of_quarter_with_time_zone_day_start_2am
    assert_result_date :quarter, "2013-01-01", "2013-01-01 10:00:00", true, day_start: 2
  end

  # year

  def test_year_end_of_year
    assert_result_date :year, "2013-01-01", "2013-12-31 23:59:59"
  end

  def test_year_start_of_year
    assert_result_date :year, "2014-01-01", "2014-01-01 00:00:00"
  end

  def test_year_end_of_year_with_time_zone
    assert_result_date :year, "2013-01-01", "2014-01-01 07:59:59", true
  end

  def test_year_start_of_year_with_time_zone
    assert_result_date :year, "2014-01-01", "2014-01-01 08:00:00", true
  end

  # year starts at 2am

  def test_year_end_of_year_day_start_2am
    assert_result_date :year, "2013-01-01", "2014-01-01 01:59:59", false, day_start: 2
  end

  def test_year_start_of_year_day_start_2am
    assert_result_date :year, "2013-01-01", "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_year_end_of_year_with_time_zone_day_start_2am
    assert_result_date :year, "2013-01-01", "2014-01-01 09:59:59", true, day_start: 2
  end

  def test_year_start_of_year_with_time_zone_day_start_2am
    assert_result_date :year, "2013-01-01", "2013-01-01 10:00:00", true, day_start: 2
  end

  # hour of day

  def test_hour_of_day_end_of_hour
    assert_result :hour_of_day, 0, "2013-01-01 00:59:59"
  end

  def test_hour_of_day_start_of_hour
    assert_result :hour_of_day, 1, "2013-01-01 01:00:00"
  end

  def test_hour_of_day_end_of_hour_with_time_zone
    assert_result :hour_of_day, 0, "2013-01-01 08:59:59", true
  end

  def test_hour_of_day_start_of_hour_with_time_zone
    assert_result :hour_of_day, 1, "2013-01-01 09:00:00", true
  end

  # hour of day starts at 2am

  def test_hour_of_day_end_of_day_day_start_2am
    assert_result :hour_of_day, 23, "2013-01-01 01:59:59", false, day_start: 2
  end

  def test_hour_of_day_start_of_day_day_start_2am
    assert_result :hour_of_day, 0, "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_hour_of_day_end_of_day_with_time_zone_day_start_2am
    assert_result :hour_of_day, 23, "2013-01-01 09:59:59", true, day_start: 2
  end

  def test_hour_of_day_start_of_day_with_time_zone_day_start_2am
    assert_result :hour_of_day, 0, "2013-01-01 10:00:00", true, day_start: 2
  end

  # minute of hour

  def test_minute_of_hour_end_of_hour
    assert_result :minute_of_hour, 59, "2017-02-09 23:59:59"
  end

  def test_minute_of_hour_beginning_of_hour
    assert_result :minute_of_hour, 0, "2017-02-09 00:00:00"
  end

  # day of week

  def test_day_of_week_end_of_day
    assert_result :day_of_week, 2, "2013-01-01 23:59:59"
  end

  def test_day_of_week_start_of_day
    assert_result :day_of_week, 3, "2013-01-02 00:00:00"
  end

  def test_day_of_week_end_of_week_with_time_zone
    assert_result :day_of_week, 2, "2013-01-02 07:59:59", true
  end

  def test_day_of_week_start_of_week_with_time_zone
    assert_result :day_of_week, 3, "2013-01-02 08:00:00", true
  end

  # day of week starts at 2am

  def test_day_of_week_end_of_day_day_start_2am
    assert_result :day_of_week, 3, "2013-01-03 01:59:59", false, day_start: 2
  end

  def test_day_of_week_start_of_day_day_start_2am
    assert_result :day_of_week, 3, "2013-01-02 02:00:00", false, day_start: 2
  end

  def test_day_of_week_end_of_day_with_time_zone_day_start_2am
    assert_result :day_of_week, 3, "2013-01-03 09:59:59", true, day_start: 2
  end

  def test_day_of_week_start_of_day_with_time_zone_day_start_2am
    assert_result :day_of_week, 3, "2013-01-02 10:00:00", true, day_start: 2
  end

  # day of week week start monday

  def test_day_of_week_end_of_day_week_start_mon
    assert_result :day_of_week, 1, "2013-01-01 23:59:59", false, week_start: :mon
  end

  def test_day_of_week_start_of_day_week_start_mon
    assert_result :day_of_week, 2, "2013-01-02 00:00:00", false, week_start: :mon
  end

  def test_day_of_week_end_of_week_with_time_zone_week_start_mon
    assert_result :day_of_week, 1, "2013-01-02 07:59:59", true, week_start: :mon
  end

  def test_day_of_week_start_of_week_with_time_zone_week_start_mon
    assert_result :day_of_week, 2, "2013-01-02 08:00:00", true, week_start: :mon
  end

  # day of month

  def test_day_of_month_end_of_day
    assert_result :day_of_month, 31, "2013-01-31 23:59:59"
  end

  def test_day_of_month_end_of_day_feb_leap_year
    assert_result :day_of_month, 29, "2012-02-29 23:59:59"
  end

  def test_day_of_month_start_of_day
    assert_result :day_of_month, 3, "2013-01-03 00:00:00"
  end

  def test_day_of_month_end_of_day_with_time_zone
    assert_result :day_of_month, 31, "2013-02-01 07:59:59", true
  end

  def test_day_of_month_start_of_day_with_time_zone
    assert_result :day_of_month, 1, "2013-01-01 08:00:00", true
  end

  # day of month starts at 2am

  def test_day_of_month_end_of_day_day_start_2am
    assert_result :day_of_month, 31, "2013-01-01 01:59:59", false, day_start: 2
  end

  def test_day_of_month_start_of_day_day_start_2am
    assert_result :day_of_month, 1, "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_day_of_month_end_of_day_with_time_zone_day_start_2am
    assert_result :day_of_month, 31, "2013-01-01 09:59:59", true, day_start: 2
  end

  def test_day_of_month_start_of_day_with_time_zone_day_start_2am
    assert_result :day_of_month, 1, "2013-01-01 10:00:00", true, day_start: 2
  end

  # month of year

  def test_month_of_year_end_of_month
    assert_result :month_of_year, 1, "2013-01-31 23:59:59"
  end

  def test_month_of_year_start_of_month
    assert_result :month_of_year, 1, "2013-01-01 00:00:00"
  end

  def test_month_of_year_end_of_month_with_time_zone
    assert_result :month_of_year, 1, "2013-02-01 07:59:59", true
  end

  def test_month_of_year_start_of_month_with_time_zone
    assert_result :month_of_year, 1, "2013-01-01 08:00:00", true
  end

  # month of year starts at 2am

  def test_month_of_year_end_of_month_day_start_2am
    assert_result :month_of_year, 12, "2013-01-01 01:59:59", false, day_start: 2
  end

  def test_month_of_year_start_of_month_day_start_2am
    assert_result :month_of_year, 1, "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_month_of_year_end_of_month_with_time_zone_day_start_2am
    assert_result :month_of_year, 12, "2013-01-01 09:59:59", true, day_start: 2
  end

  def test_month_of_year_start_of_month_with_time_zone_day_start_2am
    assert_result :month_of_year, 1, "2013-01-01 10:00:00", true, day_start: 2
  end

  # zeros

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
    create_user "2013-05-01"
    expected = {
      Date.parse("2013-05-01") => 1
    }
    assert_equal expected, call_method(:day, :created_at, range: DateTime.parse("2013-05-01")..DateTime.parse("2013-05-01"), series: true)
  end

  def test_zeros_null_value
    create_user nil
    assert_equal 0, call_method(:hour_of_day, :created_at, range: true, series: true)[0]
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

  # week_start

  def test_week_start
    Groupdate.week_start = :mon
    assert_result_date :week, "2013-03-18", "2013-03-24 23:59:59"
  end

  def test_week_start_and_start_option
    Groupdate.week_start = :mon
    assert_result_date :week, "2013-03-16", "2013-03-22 23:59:59", false, week_start: :sat
  end

  # misc

  def test_order_hour_of_day_reverse_option
    assert_equal 23, call_method(:hour_of_day, :created_at, reverse: true, series: true).keys.first
  end

  def test_time_zone
    create_user "2013-05-01"
    time_zone = "Pacific Time (US & Canada)"
    assert_equal time_zone, call_method(:hour, :created_at, time_zone: time_zone).keys.first.time_zone.name
  end

  def test_format_day
    create_user "2014-03-01"
    assert_format :day, "March 1, 2014", "%B %-e, %Y"
  end

  def test_format_month
    create_user "2014-03-01"
    assert_format :month, "March 2014", "%B %Y"
  end

  def test_format_quarter
    create_user "2014-03-05"
    assert_format :quarter, "January 1, 2014", "%B %-e, %Y"
  end

  def test_format_year
    create_user "2014-03-01"
    assert_format :year, "2014", "%Y"
  end

  def test_format_hour_of_day
    create_user "2014-03-01"
    assert_format :hour_of_day, "12 am", "%-l %P"
  end

  def test_format_hour_of_day_day_start
    create_user "2014-03-01"
    assert_format :hour_of_day, "12 am", "%-l %P", day_start: 2
  end

  def test_format_minute_of_hour
    create_user "2017-02-09"
    assert_format :minute_of_hour, "0", "%-M"
  end

  def test_format_minute_of_hour_day_start
    create_user "2017-02-09"
    assert_format :minute_of_hour, "0", "%-M", day_start: 2
  end

  def test_format_day_of_week
    create_user "2014-03-01"
    assert_format :day_of_week, "Sat", "%a"
  end

  def test_format_day_of_week_day_start
    create_user "2014-03-01"
    assert_format :day_of_week, "Fri", "%a", day_start: 2
  end

  def test_format_day_of_week_week_start
    create_user "2014-03-01"
    assert_format :day_of_week, "Sat", "%a", week_start: :mon
  end

  def test_format_day_of_week_week_start_first_key
    assert_equal "Mon", call_method(:day_of_week, :created_at, week_start: :mon, format: "%a", series: true).keys.first
  end

  def test_format_day_of_month
    create_user "2014-03-01"
    assert_format :day_of_month, " 1", "%e"
  end

  def test_format_month_of_year
    create_user "2014-01-01"
    assert_format :month_of_year, "Jan", "%b"
  end

  # date column

  def test_date_column
    expected = {
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, result(:day, "2013-05-03", false)
  end

  def test_date_column_with_time_zone
    expected = {
      Date.parse("2013-05-02") => 1
    }
    assert_equal expected, result(:day, "2013-05-03", true)
  end

  def test_date_column_with_time_zone_false
    Time.zone = pt
    create_user "2013-05-03"
    expected = {
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, call_method(:day, :created_at, time_zone: false)
  ensure
    Time.zone = nil
  end

  # date range

  def test_date_range
    ENV["TZ"] = "Europe/Oslo"
    expected = {
      Date.parse("2013-05-01") => 0,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 0
    }
    assert_equal expected, call_method(:day, :created_at, series: true, range: Date.parse("2013-05-01")..Date.parse("2013-05-03"))
  ensure
    ENV["TZ"] = "UTC"
  end

  def test_date_range_exclude_end
    ENV["TZ"] = "Europe/Oslo"
    expected = {
      Date.parse("2013-05-01") => 0,
      Date.parse("2013-05-02") => 0
    }
    assert_equal expected, call_method(:day, :created_at, series: true, range: Date.parse("2013-05-01")...Date.parse("2013-05-03"))
  ensure
    ENV["TZ"] = "UTC"
  end

  # day start

  def test_day_start_decimal_end_of_day
    assert_result_date :day, "2013-05-03", "2013-05-04 02:29:59", false, day_start: 2.5
  end

  def test_day_start_decimal_start_of_day
    assert_result_date :day, "2013-05-03", "2013-05-03 02:30:00", false, day_start: 2.5
  end

  private

  # helpers

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

  def this_quarters_month
    Time.now.beginning_of_quarter.month
  end

  def this_year
    Time.now.year
  end

  def this_month
    Time.now.month
  end

  def utc
    ActiveSupport::TimeZone["UTC"]
  end

  def pt
    ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
  end

  def brasilia
    ActiveSupport::TimeZone["Brasilia"]
  end
end
