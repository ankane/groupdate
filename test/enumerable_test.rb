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
    assert_raises(ArgumentError) { [].group_by_day(:created_at) }
  end

  def test_null
    user = create_user("2014-01-21")
    assert_raises(ArgumentError) { [user].group_by_day { nil } }
  end
end
