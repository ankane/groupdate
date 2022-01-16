require_relative "test_helper"

class AssociationsTest < Minitest::Test
  def setup
    super
    Post.delete_all
  end

  def test_works
    user = create_user("2014-03-01")
    user.posts.create!(created_at: "2014-04-01 00:00:00 UTC")
    expected = {
      Date.parse("2014-04-01") => 1
    }
    assert_equal expected, user.posts.group_by_day(:created_at).count
  end

  def test_period
    user = create_user("2014-03-01")
    user.posts.create!(created_at: "2014-04-01 00:00:00 UTC")
    expected = {
      Date.parse("2014-04-01") => 1
    }
    assert_equal expected, user.posts.group_by_period(:day, :created_at).count
  end

  # https://github.com/ankane/groupdate/issues/222#issuecomment-914343044
  def test_left_outer_joins
    date = 11.months.ago.in_time_zone(utc).to_date
    create_user(date.to_s)
    result = User.left_outer_joins(:posts).where(posts: {id: nil}).group_by_month(:created_at, last: 12, format: "%B").count
    assert_equal 1, result[date.strftime("%B")]
  end

  # https://github.com/ankane/groupdate/issues/222#issuecomment-914343044
  def test_includes
    date = 11.months.ago.in_time_zone(utc).to_date
    create_user(date.to_s)
    result = User.includes(:posts).where(posts: {id: nil}).group_by_month(:created_at, last: 12, format: "%B").count
    assert_equal 1, result[date.strftime("%B")]
  end
end
