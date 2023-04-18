require_relative "test_helper"

class RangeTest < Minitest::Test
  def test_date
    with_tz("Europe/Oslo") do
      expected = {
        Date.parse("2013-05-01") => 0,
        Date.parse("2013-05-02") => 0,
        Date.parse("2013-05-03") => 0
      }
      assert_equal expected, call_method(:day, :created_at, series: true, range: Date.parse("2013-05-01")..Date.parse("2013-05-03"))
    end
  end

  def test_date_exclude_end
    with_tz("Europe/Oslo") do
      expected = {
        Date.parse("2013-05-01") => 0,
        Date.parse("2013-05-02") => 0
      }
      assert_equal expected, call_method(:day, :created_at, series: true, range: Date.parse("2013-05-01")...Date.parse("2013-05-03"))
    end
  end

  def test_string
    error = assert_raises(ArgumentError) do
      call_method(:day, :created_at, range: "2013-05-01".."2013-05-04")
    end
    assert_equal "Range bounds should be Date or Time, not String", error.message
  end

  def test_numeric
    error = assert_raises(ArgumentError) do
      call_method(:day, :created_at, range: 1..3)
    end
    assert_equal "Range bounds should be Date or Time, not Integer", error.message
  end

  def test_time
    create_user "2013-05-01"
    create_user "2013-05-02"

    expected = {
      Date.parse("2013-05-01") => 1
    }
    today = Date.parse("2013-05-01").to_time
    assert_equal expected, call_method(:day, :created_at, series: true, range: today..today.end_of_day)
  end

  def test_datetime
    create_user "2013-05-01"
    create_user "2013-05-02"

    expected = {
      Date.parse("2013-05-01") => 1
    }
    today = Date.parse("2013-05-01").to_datetime
    assert_equal expected, call_method(:day, :created_at, series: true, range: today..today.end_of_day)
  end

  # expand range

  def test_expand_range
    create_user "2013-01-01"
    create_user "2013-12-31"

    # enumerable does not filter values
    expected = {Date.parse("2013-01-01") => enumerable? ? 2 : 0}
    assert_equal expected, call_method(:year, :created_at, series: true, range: Date.parse("2013-01-02")..Date.parse("2013-12-30"))

    expected = {Date.parse("2013-01-01") => 2}
    assert_equal expected, call_method(:year, :created_at, series: true, range: Date.parse("2013-01-02")..Date.parse("2013-12-30"), expand_range: true)
  end

  def test_expand_range_exclude_end
    create_user "2013-12-31"
    create_user "2014-01-01"

    expected = {Date.parse("2013-01-01") => 1}
    assert_equal expected, call_method(:year, :created_at, series: true, range: Date.parse("2013-01-02")...Date.parse("2014-01-01"), expand_range: true)

    expected = {Date.parse("2013-01-01") => 1, Date.parse("2014-01-01") => 1}
    assert_equal expected, call_method(:year, :created_at, series: true, range: Date.parse("2013-01-02")..Date.parse("2014-01-01"), expand_range: true)
  end

  # beginless range

  def test_beginless
    skip unless beginless_range_supported?

    create_user "2013-05-01"
    create_user "2013-05-04 12:00:00"
    create_user "2013-06-01"
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 0,
      Date.parse("2013-05-04") => 1
    }
    assert_equal expected, call_method(:day, :created_at, series: true, range: eval('..Date.parse("2013-05-04")'))
  end

  def test_beginless_exclude_end
    skip unless beginless_range_supported?

    create_user "2013-05-01"
    create_user "2013-06-01"
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 0
    }
    assert_equal expected, call_method(:day, :created_at, series: true, range: eval('...Date.parse("2013-05-04")'))
  end

  def test_beginless_empty
    skip unless beginless_range_supported?

    assert_empty call_method(:day, :created_at, series: true, range: eval('..Date.parse("2013-05-04")'))
  end

  def beginless_range_supported?
    RUBY_VERSION.to_f >= 2.7
  end

  # endless range

  def test_endless
    create_user "2013-01-01"
    create_user "2013-05-03"
    expected = {
      Date.parse("2013-05-01") => 0,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, call_method(:day, :created_at, series: true, range: eval('Date.parse("2013-05-01")..'))
  end

  def test_endless_empty
    assert_empty call_method(:day, :created_at, series: true, range: eval('Date.parse("2013-05-01")..'))
  end

  # beginless and endless range

  def test_beginless_and_endless
    create_user "2013-05-01"
    create_user "2013-05-03"
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, call_method(:day, :created_at, series: true, range: nil..nil)
  end

  def with_tz(tz)
    ENV["TZ"] = tz
    yield
  ensure
    ENV["TZ"] = "UTC"
  end
end
