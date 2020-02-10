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
end
