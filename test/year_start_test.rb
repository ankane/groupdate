require_relative "test_helper"

class YearStartTest < Minitest::Test
  # year starting in April

  def test_year_end_of_year
    assert_result_date :year, "2013-04-01", "2014-03-31 23:59:59", false, year_start: :april
  end

  def test_year_start_of_year
    assert_result_date :year, "2014-04-01", "2014-04-01 00:00:00", false, year_start: :april
  end

  def test_year_end_of_year_with_time_zone
    assert_result_date :year, "2013-04-01", "2014-04-01 06:59:59", true, year_start: :april
  end

  def test_year_start_of_year_with_time_zone
    assert_result_date :year, "2014-04-01", "2014-04-01 08:00:00", true, year_start: :april
  end

  # invalid

  def test_invalid
    skip "call_method expects different error message" if sqlite?

    error = assert_raises(ArgumentError) do
      call_method(:year, :created_at, year_start: "bad")
    end
    assert_equal "Unrecognized :year_start option", error.message
  end
end
