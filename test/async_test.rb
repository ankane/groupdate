require_relative "test_helper"

class AsyncTest < Minitest::Test
  def setup
    skip if ActiveRecord::VERSION::STRING.to_f < 7.1 || enumerable?
    super
  end

  def test_count
    create_user "2013-05-01"
    create_user "2013-05-03"
    create_user "2013-05-03", 9
    promise = User.group_by_day(:created_at).async_count
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 2
    }
    assert_equal expected, promise.value
  end

  def test_sum
    create_user "2013-05-01"
    create_user "2013-05-03"
    create_user "2013-05-03", 9
    promise = User.group_by_day(:created_at).async_sum(:score)
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 10
    }
    assert_equal expected, promise.value
  end

  def test_minimum
    create_user "2013-05-01"
    create_user "2013-05-03"
    create_user "2013-05-03", 9
    promise = User.group_by_day(:created_at).async_minimum(:score)
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => nil,
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, promise.value
  end

  def test_maximum
    create_user "2013-05-01"
    create_user "2013-05-03"
    create_user "2013-05-03", 9
    promise = User.group_by_day(:created_at).async_maximum(:score)
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => nil,
      Date.parse("2013-05-03") => 9
    }
    assert_equal expected, promise.value
  end

  def test_average
    create_user "2013-05-01"
    create_user "2013-05-03"
    create_user "2013-05-03", 9
    promise = User.group_by_day(:created_at).async_average(:score)
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => nil,
      Date.parse("2013-05-03") => 5
    }
    assert_equal expected, promise.value
  end

  def test_then
    create_user "2013-05-01"
    create_user "2013-05-03"
    create_user "2013-05-03", 9
    promise = User.group_by_day(:created_at).async_count
    expected = {
      Date.parse("2013-05-01") => 10,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 20
    }
    assert_equal expected, promise.then { |s| s.transform_values { |v| v * 10 } }.value
  end

  def test_status
    promise = User.group_by_day(:created_at).async_count
    if sqlite?
      refute promise.pending?
    else
      assert promise.pending?
    end
    assert_empty promise.value
    refute promise.pending?
  end
end
