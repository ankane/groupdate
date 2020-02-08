require_relative "test_helper"

class BasicTest < Minitest::Test
  # second

  def test_second_end_of_second
    assert_result_time :second, "2013-05-03 00:00:00 UTC", "2013-05-03 00:00:00.999"
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

  # day of year

  def test_day_of_year_end_of_day
    assert_result :day_of_year, 1, "2013-01-01 23:59:59"
  end

  def test_day_of_year_start_of_day
    assert_result :day_of_year, 2, "2013-01-02 00:00:00"
  end

  def test_day_of_year_end_of_week_with_time_zone
    assert_result :day_of_year, 1, "2013-01-02 07:59:59", true
  end

  def test_day_of_year_start_of_week_with_time_zone
    assert_result :day_of_year, 2, "2013-01-02 08:00:00", true
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

  # misc

  def test_order_hour_of_day_reverse_option
    assert_equal 23, call_method(:hour_of_day, :created_at, reverse: true, series: true).keys.first
  end

  def test_time_zone
    create_user "2013-05-01"
    time_zone = "Pacific Time (US & Canada)"
    assert_equal time_zone, call_method(:hour, :created_at, time_zone: time_zone).keys.first.time_zone.name
  end

  # date column

  def test_date_column
    expected = {
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, result(:day, "2013-05-03", false, :created_on)
  end

  def test_date_column_with_time_zone
    expected = {
      Date.parse("2013-05-02") => 1
    }
    assert_equal expected, result(:day, "2013-05-03", true, :created_on)
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

  # endless range

  def test_endless_range
    skip if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.6.0")

    assert_raises Groupdate::Error do
      call_method(:day, :created_at, series: true, range: eval('Date.parse("2013-05-01")..'))
    end
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

  # Brasilia Summer Time

  def test_brasilia_summer_time
    brasilia = ActiveSupport::TimeZone["Brasilia"]
    create_user(brasilia.parse("2014-10-19 02:00:00").utc.to_s)
    create_user(brasilia.parse("2014-10-20 02:00:00").utc.to_s)
    expected = {
      Date.parse("2014-10-19") => 1,
      Date.parse("2014-10-20") => 1
    }
    assert_equal expected, call_method(:day, :created_at, time_zone: "Brasilia")
  end

  def test_brasilia_summer_time_2018
    create_user("2018-11-01 00:00:00")
    expected = {
      Date.parse("2018-10-28") => 1
    }
    assert_equal expected, call_method(:week, :created_at, time_zone: "Brasilia")
  end

  # extra tests for week

  def test_week_middle_of_week_with_time_zone
    assert_result_date :week, "2013-03-10", "2013-03-11 07:15:00", true
  end

  def test_week_middle_of_week_with_time_zone_frequently
    skip # takes while

    # before and after DST weeks
    weeks = ["2013-03-03", "2013-03-10", "2013-03-17", "2013-10-27", "2013-11-03", "2013-11-10"]
    weekdays = [:sun, :mon, :tue, :wed, :thu, :fri, :sat]
    hours = [0, 1, 2, 3, 21, 22]

    hours.each do |hour|
      puts hour
      weekdays.each_with_index do |week_start, i|
        puts week_start
        weeks.each do |week|
          puts week
          start_at = (pt.parse(week) + i.days).change(hour: hour)
          time = start_at.dup
          end_at = (time + 1.week).change(hour: hour)
          while time < end_at
            # prevent mysql error
            if time.utc.to_s != "2013-03-10 02:00:00 UTC"
              assert_result_date :week, start_at.strftime("%Y-%m-%d"), time.utc.to_s, true, week_start: week_start, day_start: hour
              User.delete_all
            end
            time += 1.hour
          end
        end
      end
    end
  end
end
