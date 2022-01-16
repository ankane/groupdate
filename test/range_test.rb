require_relative "test_helper"

class RangeTest < Minitest::Test
  def test_range_date
    with_tz("Europe/Oslo") do
      expected = {
        Date.parse("2013-05-01") => 0,
        Date.parse("2013-05-02") => 0,
        Date.parse("2013-05-03") => 0
      }
      assert_equal expected, call_method(:day, :created_at, series: true, range: Date.parse("2013-05-01")..Date.parse("2013-05-03"))
    end
  end

  def test_range_date_exclude_end
    with_tz("Europe/Oslo") do
      expected = {
        Date.parse("2013-05-01") => 0,
        Date.parse("2013-05-02") => 0
      }
      assert_equal expected, call_method(:day, :created_at, series: true, range: Date.parse("2013-05-01")...Date.parse("2013-05-03"))
    end
  end

  def test_range_string
    error = assert_raises(ArgumentError) do
      call_method(:day, :created_at, range: "2013-05-01".."2013-05-04")
    end
    assert_equal "Range bounds should be Date or Time, not String", error.message
  end

  def test_range_numeric
    error = assert_raises(ArgumentError) do
      call_method(:day, :created_at, range: 1..3)
    end
    assert_equal "Range bounds should be Date or Time, not Integer", error.message
  end

  # beginless range

  def test_beginless_range
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

  def test_beginless_range_exclude_end
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

  def test_beginless_range_empty
    skip unless beginless_range_supported?

    assert_empty call_method(:day, :created_at, series: true, range: eval('..Date.parse("2013-05-04")'))
  end

  def beginless_range_supported?
    RUBY_VERSION.to_f >= 2.7
  end

  # endless range

  def test_endless_range
    skip unless endless_range_supported?

    create_user "2013-01-01"
    create_user "2013-05-03"
    expected = {
      Date.parse("2013-05-01") => 0,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, call_method(:day, :created_at, series: true, range: eval('Date.parse("2013-05-01")..'))
  end

  def test_endless_range_empty
    skip unless endless_range_supported?

    assert_empty call_method(:day, :created_at, series: true, range: eval('Date.parse("2013-05-01")..'))
  end

  def endless_range_supported?
    RUBY_VERSION.to_f >= 2.6
  end

  # beginless and endless range

  def test_beginless_and_endless_range
    skip unless beginless_and_endless_range_supported?

    create_user "2013-05-01"
    create_user "2013-05-03"
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, call_method(:day, :created_at, series: true, range: nil..nil)
  end

  def beginless_and_endless_range_supported?
    RUBY_VERSION.to_f >= 2.6
  end

  def with_tz(tz)
    ENV["TZ"] = tz
    yield
  ensure
    ENV["TZ"] = "UTC"
  end
end
