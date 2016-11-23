require_relative "test_helper"
require "ostruct"

class TestEnumerable < Minitest::Test
  include TestGroupdate

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

  def test_missing_required_options_for_time_range
    assert_raises(RuntimeError) { [].group_by_time_range(&:created_at) }
  end

  def test_group_by_time_range
    user_a = create_user("2014-01-07")
    user_b = create_user("2014-01-14")
    user_c = create_user("2014-02-04")
    expected = {
      Date.parse("2014-01-06") => [user_a, user_b],
      Date.parse("2014-01-20") => [],
      Date.parse("2014-02-03") => [user_c]
    }
    assert_equal expected, [user_a, user_b, user_c].group_by_time_range(
      series: true,
      time_range_end: Date.parse("2014-02-17"), time_range_length: 2.weeks, time_ranges_count: 3,
      &:created_at)
  end

  def test_no_block
    assert_raises(ArgumentError) { [].group_by_day(:created_at) }
  end

  def call_method(method, field, options)
    Hash[@users.group_by_period(method, options) { |u| u.send(field) }.map { |k, v| [k, v.size] }]
  end

  def create_user(created_at, score = 1)
    user =
      OpenStruct.new(
        name: "Andrew",
        score: score,
        created_at: created_at ? utc.parse(created_at) : nil,
        created_on: created_at ? Date.parse(created_at) : nil
      )
    @users << user
    user
  end

  def setup
    super
    @users = []
  end

  def teardown
    # do nothing
  end

  def enumerable_test?
    true
  end
end
