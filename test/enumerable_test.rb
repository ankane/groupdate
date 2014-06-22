require_relative "test_helper"

class TestEnumerable < Minitest::Test
  include TestGroupdate

  def test_enumerable
    user_a = User.new(created_at: utc.parse("2014-01-21"))
    user_b = User.new(created_at: utc.parse("2014-03-14"))
    expected = {
      utc.parse("2014-01-01") => [user_a],
      utc.parse("2014-02-01") => [],
      utc.parse("2014-03-01") => [user_b]
    }
    assert_equal expected, [user_a, user_b].group_by_month(&:created_at)
  end

  def call_method(method, field, options)
    Hash[ User.all.to_a.send(:"group_by_#{method}", options){|u| u.send(field) }.map{|k, v| [k, v.size] } ]
  end

end
