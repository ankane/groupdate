require_relative "test_helper"

class EnumerableTest < Minitest::Test
  def test_enumerable
    user_a = create_user("2014-01-21")
    user_b = create_user("2014-03-14")
    expected = {
      Date.parse("2014-01-01") => [user_a],
      Date.parse("2014-03-01") => [user_b]
    }
    assert_equal expected, [user_a, user_b].group_by_month(&:created_at)
  end

  def test_enumerable_series
    user_a = create_user("2014-01-21")
    user_b = create_user("2014-03-14")
    expected = {
      Date.parse("2014-01-01") => [user_a],
      Date.parse("2014-02-01") => [],
      Date.parse("2014-03-01") => [user_b]
    }
    assert_equal expected, [user_a, user_b].group_by_month(series: true, &:created_at)
  end

  def test_no_block
    error = assert_raises(ArgumentError) do
      [].group_by_day(:created_at)
    end
    assert_equal "no block given", error.message
  end

  def test_null
    user = create_user("2014-01-21")
    error = assert_raises(ArgumentError) do
      [user].group_by_day { nil }
    end
    assert_equal "Not a time", error.message
  end

  def test_too_many_arguments
    error = assert_raises(ArgumentError) do
      [].group_by_day(:bad) { nil }
    end
    assert_equal "wrong number of arguments (given 1, expected 0)", error.message
  end

  def test_too_many_arguments_group_by_period
    error = assert_raises(ArgumentError) do
      [].group_by_period(:day, :bad) { nil }
    end
    assert_equal "wrong number of arguments (given 2, expected 1)", error.message
  end

  def test_permit
    error = assert_raises(ArgumentError) do
      [].group_by_period(:day, permit: %w(week)) { nil }
    end
    assert_equal "Unpermitted period", error.message
  end

  def test_minute_n
    user_a = create_user("2014-01-21 00:01:23")
    user_b = create_user("2014-01-22 00:04:56")
    assert_equal 145, [user_a, user_b].group_by_minute(series: true, n: 10, &:created_at).size
  end

  def test_enumerable_last_complete_periods
    now = Time.now.utc
    current_month = Time.utc(now.year, now.month, 1)
    older = create_user(current_month - 3.months + 1.day)
    second_previous = create_user(current_month - 2.months + 1.day)
    previous = create_user(current_month - 1.month + 1.day)

    result = [older, second_previous, previous].group_by_month(
      last: 2,
      current: false,
      time_zone: "Etc/UTC"
    ) { |user| user.created_at }

    assert_equal [(current_month - 2.months).to_date, (current_month - 1.month).to_date], result.keys
  end
end
