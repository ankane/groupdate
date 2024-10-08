require_relative "test_helper"

class DatabaseTest < Minitest::Test
  def test_zeros_previous_scope
    create_user "2013-05-01"
    expected = {
      Date.parse("2013-05-01") => 0
    }
    assert_equal expected, User.where("id = 0").group_by_day(:created_at, range: Date.parse("2013-05-01")..Date.parse("2013-05-01 23:59:59 UTC")).count
  end

  def test_previous_scopes
    create_user "2013-05-01"
    assert_empty User.where("id = 0").group_by_day(:created_at).count
  end

  def test_where_after
    skip if sqlite?

    create_user "2013-05-01"
    create_user "2013-05-02"
    expected = {Date.parse("2013-05-02") => 1}
    assert_equal expected, User.group_by_day(:created_at).where("created_at > ?", "2013-05-01").count
  end

  def test_not_modified
    create_user "2013-05-01"
    expected = {Date.parse("2013-05-01") => 1}
    relation = User.group_by_day(:created_at)
    relation.where("created_at > ?", "2013-05-01")
    assert_equal expected, relation.count
  end

  def test_bad_method
    assert_raises(NoMethodError) do
      User.group_by_day(:created_at).no_such_method
    end
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
    assert_equal expected, call_method(:month, :created_on, last: 2, time_zone: false)
  ensure
    Time.zone = nil
  end

  def test_last_hour_of_day
    error = assert_raises(ArgumentError) do
      User.group_by_hour_of_day(:created_at, last: 3).count
    end
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

  def test_current_no_last_empty_data
    expected = {}
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

  # activerecord default_timezone option

  def test_default_timezone_local
    base_class = ActiveRecord::VERSION::MAJOR >= 7 ? ActiveRecord : User
    base_class.default_timezone = :local
    error = assert_raises(Groupdate::Error) do
      User.group_by_day(:created_at).count
    end
    assert_match "must be :utc", error.message
  ensure
    base_class.default_timezone = :utc
  end

  # carry_forward option

  def test_carry_forward
    create_user "2014-05-01"
    create_user "2014-05-01"
    create_user "2014-05-03"
    assert_equal 2, User.group_by_day(:created_at, carry_forward: true).count[Date.parse("2014-05-02")]
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

  # unscope

  def test_unscope
    assert_equal User.all, User.group_by_day(:created_at).unscoped.all
  end

  # currently loses groupdate_values
  # def test_except_where
  #   create_user "2014-05-01"
  #   expected = {
  #     Date.parse("2017-01-01") => 0
  #   }
  #   assert_equal expected, User.group_by_year(:created_at, range: Date.parse("2017-01-01")...Date.parse("2018-01-01")).except(:where).count
  # end

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

  # n

  def test_n
    create_user("2014-01-21 00:12:34")
    create_user("2014-01-22 00:56:12")
    result = User.group_by_minute(:created_at, n: 10).count
    assert_equal 149, result.size
    assert_equal 1, result[utc.parse("2014-01-21 00:10:00")]
    assert_equal 1, result[utc.parse("2014-01-22 00:50:00")]
  end

  def test_n_relation
    create_user("2014-01-21 00:12:34")
    create_user("2014-01-22 00:56:12")
    result = User.all.group_by_minute(:created_at, n: 10).count
    assert_equal 149, result.size
    assert_equal 1, result[utc.parse("2014-01-21 00:10:00")]
    assert_equal 1, result[utc.parse("2014-01-22 00:50:00")]
  end

  def test_n_last
    result = User.group_by_minute(:created_at, n: 10, last: 3).count
    assert_equal 3, result.size
  end

  def test_n_duration
    assert_equal({}, User.group_by_second(:created_at, n: 2.minutes).count)
  end

  def test_connection_leasing
    ActiveRecord::Base.connection_handler.clear_active_connections!
    assert_nil ActiveRecord::Base.connection_pool.active_connection?
    User.group_by_day(:created_at).count
    assert_nil ActiveRecord::Base.connection_pool.active_connection?
  end

  private

  def this_year
    Time.now.year
  end

  def this_month
    Time.now.month
  end
end
