require_relative "test_helper"

class DatabaseTest < Minitest::Test
  def test_zeros_previous_scope
    create_user "2013-05-01"
    expected = {
      Date.parse("2013-05-01") => 0
    }
    assert_equal expected, User.where("id = 0").group_by_day(:created_at, range: Date.parse("2013-05-01")..Date.parse("2013-05-01 23:59:59 UTC")).count
  end

  def test_table_name
    # This test is to ensure there's not an error when using the table
    # name as part of the column name.
    assert_empty User.group_by_day("users.created_at").count
  end

  def test_previous_scopes
    create_user "2013-05-01"
    assert_empty User.where("id = 0").group_by_day(:created_at).count
  end

  def test_where_after
    skip if ENV["ADAPTER"] == "sqlite"

    create_user "2013-05-01"
    create_user "2013-05-02"
    expected = {Date.parse("2013-05-02") => 1}
    assert_equal expected, User.group_by_day(:created_at).where("created_at > ?", "2013-05-01").count
  end

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

  def test_not_modified
    create_user "2013-05-01"
    expected = {Date.parse("2013-05-01") => 1}
    relation = User.group_by_day(:created_at)
    relation.where("created_at > ?", "2013-05-01")
    assert_equal expected, relation.count
  end

  def test_bad_method
    assert_raises(NoMethodError) { User.group_by_day(:created_at).no_such_method }
  end

  def test_respond_to_order
    assert User.group_by_day(:created_at).respond_to?(:order)
  end

  def test_respond_to_bad_method
    assert !User.group_by_day(:created_at).respond_to?(:no_such_method)
  end

  def test_last
    create_user "#{this_year - 3}-01-01"
    create_user "#{this_year - 1}-01-01"
    expected = {
      Date.parse("#{this_year - 2}-01-01") => 0,
      Date.parse("#{this_year - 1}-01-01") => 1,
      Date.parse("#{this_year}-01-01") => 0
    }
    assert_equal expected, User.group_by_year(:created_at, last: 3).count
  end

  def test_last_date
    Time.zone = pt
    today = Time.zone.now.to_date
    create_user today.to_s
    this_month = pt.parse(today.to_s).beginning_of_month
    last_month = this_month - 1.month
    expected = {
      last_month.to_date => 0,
      this_month.to_date => 1
    }
    assert_equal expected, call_method(:month, :created_on, last: 2)
  ensure
    Time.zone = nil
  end

  def test_last_hour_of_day
    error = assert_raises(ArgumentError) { User.group_by_hour_of_day(:created_at, last: 3).count }
    assert_equal "Cannot use last option with hour_of_day", error.message
  end

  def test_current
    create_user "#{this_year - 3}-01-01"
    create_user "#{this_year - 1}-01-01"
    expected = {
      Date.parse("#{this_year - 2}-01-01") => 0,
      Date.parse("#{this_year - 1}-01-01") => 1
    }
    assert_equal expected, User.group_by_year(:created_at, last: 2, current: false).count
  end

  def test_current_no_last
    create_user "#{this_year - 2}-01-01"
    create_user "#{this_year}-01-01"
    expected = {
      Date.parse("#{this_year - 2}-01-01") => 1,
      Date.parse("#{this_year - 1}-01-01") => 0
    }
    assert_equal expected, User.group_by_year(:created_at, current: false).count
  end

  def test_quarter_and_last
    today = Date.today
    create_user today.to_s
    this_quarter = today.to_time.beginning_of_quarter
    last_quarter = this_quarter - 3.months
    expected = {
      last_quarter.to_date => 0,
      this_quarter.to_date => 1
    }
    assert_equal expected, call_method(:quarter, :created_at, last: 2)
  end

  def test_format_multiple_groups
    create_user "2014-03-01"
    assert_equal ({["Sun", 1] => 1}), User.group_by_week(:created_at, format: "%a").group(:score).count
    assert_equal ({[1, "Sun"] => 1}), User.group(:score).group_by_week(:created_at, format: "%a").count
  end

  # permit

  def test_permit
    error = assert_raises(ArgumentError) { User.group_by_period(:day, :created_at, permit: %w(week)).count }
    assert_equal "Unpermitted period", error.message
  end

  def test_permit_bad_period
    error = assert_raises(ArgumentError) { User.group_by_period(:bad_period, :created_at).count }
    assert_equal "Unpermitted period", error.message
  end

  def test_permit_symbol_symbols
    assert_equal ({}), User.group_by_period(:day, :created_at, permit: [:day]).count
  end

  def test_permit_string_symbols
    assert_equal ({}), User.group_by_period("day", :created_at, permit: [:day]).count
  end

  def test_permit_symbol_strings
    assert_equal ({}), User.group_by_period(:day, :created_at, permit: %w(day)).count
  end

  def test_permit_string_strings
    assert_equal ({}), User.group_by_period("day", :created_at, permit: %w(day)).count
  end

  # default value

  def test_default_value
    create_user "#{this_year}-01-01"
    expected = {
      Date.parse("#{this_year - 1}-01-01") => nil,
      Date.parse("#{this_year}-01-01") => 1
    }
    assert_equal expected, User.group_by_year(:created_at, last: 2, default_value: nil).count
  end

  def test_default_value_defaults
    assert_equal 0, User.group_by_year(:created_at, last: 1).count.values.first
    assert_equal 0, User.group_by_year(:created_at, last: 1).sum(:id).values.first
    assert_nil User.group_by_year(:created_at, last: 1).average(:id).values.first
    assert_nil User.group_by_year(:created_at, last: 1).maximum(:id).values.first
    assert_nil User.group_by_year(:created_at, last: 1).minimum(:id).values.first
  end

  # associations

  def test_associations
    user = create_user("2014-03-01")
    user.posts.create!(created_at: "2014-04-01 00:00:00 UTC")
    expected = {
      Date.parse("2014-04-01") => 1
    }
    assert_equal expected, user.posts.group_by_day(:created_at).count
  end

  def test_associations_period
    user = create_user("2014-03-01")
    user.posts.create!(created_at: "2014-04-01 00:00:00 UTC")
    expected = {
      Date.parse("2014-04-01") => 1
    }
    assert_equal expected, user.posts.group_by_period(:day, :created_at).count
  end

  # activerecord default_timezone option

  def test_default_timezone_local
    User.default_timezone = :local
    assert_raises(Groupdate::Error) { User.group_by_day(:created_at).count }
  ensure
    User.default_timezone = :utc
  end

  # Brasilia Summer Time

  def test_brasilia_summer_time
    brasilia = ActiveSupport::TimeZone["Brasilia"]
    create_user(brasilia.parse("2014-10-19 02:00:00").utc.to_s)
    create_user(brasilia.parse("2014-10-20 02:00:00").utc.to_s)
    expected = {
      Date.parse("2014-10-19") => 1,
      Date.parse("2014-10-20") => 1
    }
    assert_equal expected, call_method(:day, :created_at, time_zone: "Brasilia")
  end

  # carry_forward option

  def test_carry_forward
    create_user "2014-05-01"
    create_user "2014-05-01"
    create_user "2014-05-03"
    assert_equal 2, User.group_by_day(:created_at, carry_forward: true).count[Date.parse("2014-05-02")]
  end

  # no column

  def test_no_column
    assert_raises(ArgumentError) { User.group_by_day.first }
  end

  # custom model calculation methods

  def test_custom_model_calculation_method
    create_user "2014-05-01"
    create_user "2014-05-01"
    create_user "2014-05-03"

    expected = {
      Date.parse("2014-05-01") => 2,
      Date.parse("2014-05-02") => 0,
      Date.parse("2014-05-03") => 1
    }

    assert_equal expected, User.group_by_day(:created_at).custom_count
  end

  def test_using_listed_but_undefined_custom_calculation_method_raises_error
    assert_raises(NoMethodError) do
      User.group_by_day(:created_at).undefined_calculation
    end
  end

  # unscope

  def test_unscope
    assert_equal User.all, User.group_by_day(:created_at).unscoped.all
  end

  # pluck

  def test_pluck
    create_user "2014-05-01"
    assert_equal [0], User.group_by_hour_of_day(:created_at).pluck(0)
  end

  # test relation

  def test_relation
    assert User.group_by_day(:created_at).is_a?(ActiveRecord::Relation)
  end

  # null

  def test_null
    create_user nil
    assert_equal 0, call_method(:hour_of_day, :created_at, range: true, series: true)[0]
  end

  # bad column

  def test_bad_column
    create_user "2018-01-01"
    assert_raises { User.group_by_day(:name).count }
  end

  def this_year
    Time.now.year
  end

  def this_month
    Time.now.month
  end
end
