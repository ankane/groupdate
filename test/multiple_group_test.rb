require_relative "test_helper"

class MultipleGroupTest < Minitest::Test
  def test_group_before
    create_user "2013-05-01", 1
    create_user "2013-05-02", 2
    create_user "2013-05-03", 2
    expected = {
      [1, Date.parse("2013-05-01")] => 1,
      [1, Date.parse("2013-05-02")] => 0,
      [1, Date.parse("2013-05-03")] => 0,
      [2, Date.parse("2013-05-01")] => 0,
      [2, Date.parse("2013-05-02")] => 1,
      [2, Date.parse("2013-05-03")] => 1
    }
    assert_equal expected, User.group(:score).group_by_day(:created_at).order(:score).count
  end

  def test_group_after
    create_user "2013-05-01", 1
    create_user "2013-05-02", 2
    create_user "2013-05-03", 2
    expected = {
      [Date.parse("2013-05-01"), 1] => 1,
      [Date.parse("2013-05-02"), 1] => 0,
      [Date.parse("2013-05-03"), 1] => 0,
      [Date.parse("2013-05-01"), 2] => 0,
      [Date.parse("2013-05-02"), 2] => 1,
      [Date.parse("2013-05-03"), 2] => 1
    }
    assert_equal expected, User.group_by_day(:created_at).group(:score).order(:score).count
  end

  def test_group_day_of_week
    create_user "2013-05-01", 1
    create_user "2013-05-02", 2
    create_user "2013-05-03", 2
    expected = {
      [1, 0] => 0,
      [1, 1] => 0,
      [1, 2] => 0,
      [1, 3] => 1,
      [1, 4] => 0,
      [1, 5] => 0,
      [1, 6] => 0,
      [2, 0] => 0,
      [2, 1] => 0,
      [2, 2] => 0,
      [2, 3] => 0,
      [2, 4] => 1,
      [2, 5] => 1,
      [2, 6] => 0
    }
    assert_equal expected, User.group(:score).group_by_day_of_week(:created_at).count
  end

  def test_groupdate_multiple
    create_user "2013-05-01", 1
    expected = {
      [Date.parse("2013-05-01"), Date.parse("2013-01-01")] => 1
    }
    assert_equal expected, User.group_by_day(:created_at).group_by_year(:created_at).count
  end

  def test_groupdate_multiple_hour_of_day_day_of_week
    create_user "2013-05-01 00:00:00 UTC", 1
    expected = {}
    24.times do |i|
      7.times do |j|
        expected[[i, j]] = i == 0 && j == 3 ? 1 : 0
      end
    end
    assert_equal expected, User.group_by_hour_of_day(:created_at).group_by_day_of_week(:created_at).count
  end

  def test_format_multiple_groups
    create_user "2014-03-01"
    assert_equal ({["Sun", 1] => 1}), User.group_by_week(:created_at, format: "%a").group(:score).count
    assert_equal ({[1, "Sun"] => 1}), User.group(:score).group_by_week(:created_at, format: "%a").count
  end
end
