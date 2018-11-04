require_relative "test_helper"

class FormatTest < Minitest::Test
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
end
