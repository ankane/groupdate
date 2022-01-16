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

  # column values

  def test_column_string
    assert_empty User.group("created_at").count
    assert_empty User.group_by_day("created_at").count
  end

  def test_column_table_name
    assert_empty User.group("users.created_at").count
    assert_empty User.group_by_day("users.created_at").count
  end

  def test_column_string_with_join
    assert_empty User.joins(:posts).group("created_at").count
    assert_empty User.joins(:posts).group_by_day("created_at").count
  end

  def test_column_string_function
    function = now_function
    error = assert_raises(ActiveRecord::UnknownAttributeReference) do
      User.joins(:posts).group_by_day(now_function).count
    end
    assert_equal "Query method called with non-attribute argument(s): \"#{function}\". Use Arel.sql() for known-safe values.", error.message
  end

  def test_column_string_function_arel
    function = now_function
    assert_empty User.joins(:posts).group_by_day(Arel.sql(function)).count
  end

  def test_column_symbol_with_join
    assert_empty User.joins(:posts).group(:created_at).count
    assert_empty User.joins(:posts).group_by_day(:created_at).count
  end

  def test_column_symbol_undefined_attribute
    create_user "2018-01-01"

    # for sqlite, double-quoted string literals are accepted
    # https://www.sqlite.org/quirks.html
    if sqlite?
      assert_equal ({"created_at2" => 1}), User.group(:created_at2).count

      error = assert_raises(Groupdate::Error) do
        User.group_by_day(:created_at2).count
      end
      assert_equal "Invalid query - be sure to use a date or time column", error.message
    else
      assert_raises(ActiveRecord::StatementInvalid) do
        User.group(:created_at2).count
      end
      assert_raises(ActiveRecord::StatementInvalid) do
        User.group_by_day(:created_at2).count
      end
    end
  end

  def test_column_symbol_quoted
    sql = User.group_by_day(:missing).to_sql
    quoted_name = User.connection.quote_column_name("missing")
    refute_equal quoted_name, "missing"
    assert_match quoted_name, sql
    # important: makes sure all instances are quoted
    assert_equal sql.split("missing").size, sql.split(quoted_name).size
  end

  def test_column_alias_attribute
    assert_empty User.group(:signed_up_at).count
    assert_empty User.group_by_day(:signed_up_at).count
  end

  # associations

  def test_associations
    user = create_user("2014-03-01")
    user.posts.create!(created_at: "2014-04-01 00:00:00 UTC")
    expected = {
      Date.parse("2014-04-01") => 1
    }
    assert_equal expected, user.posts.group_by_day(:created_at).count
  ensure
    Post.delete_all
  end

  def test_associations_period
    user = create_user("2014-03-01")
    user.posts.create!(created_at: "2014-04-01 00:00:00 UTC")
    expected = {
      Date.parse("2014-04-01") => 1
    }
    assert_equal expected, user.posts.group_by_period(:day, :created_at).count
  ensure
    Post.delete_all
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

  # no column

  def test_no_column
    error = assert_raises(ArgumentError) do
      User.group_by_day.first
    end
    assert_equal "wrong number of arguments (given 0, expected 1)", error.message
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

  # bad column

  def test_bad_column
    create_user "2018-01-01"
    assert_raises do
      User.group_by_day(:name).count
    end
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

  private

  def this_year
    Time.now.year
  end

  def this_month
    Time.now.month
  end

  def now_function
    if sqlite?
      "datetime('now')"
    elsif redshift?
      "GETDATE()"
    else
      "NOW()"
    end
  end
end
