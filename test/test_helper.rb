require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "logger"
require "active_record"

Minitest::Test = Minitest::Unit::TestCase unless defined?(Minitest::Test)

ENV["TZ"] = "UTC"

# for debugging
# ActiveRecord::Base.logger = Logger.new(STDOUT)

# rails does this in activerecord/lib/active_record/railtie.rb
ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true

class User < ActiveRecord::Base
  has_many :posts

  def self.groupdate_calculation_methods
    [:custom_count, :undefined_calculation]
  end

  def self.custom_count
    count
  end

  def self.unlisted_calculation
    count
  end
end

class Post < ActiveRecord::Base
end

# i18n
I18n.enforce_available_locales = true
I18n.backend.store_translations :de, date: {
  abbr_month_names: %w(Jan Feb Mar Apr Mai Jun Jul Aug Sep Okt Nov Dez).unshift(nil)
},
time: {
  formats: {special: "%b %e, %Y"}
}

# migrations
def create_tables
  ActiveRecord::Migration.verbose = false

  ActiveRecord::Migration.create_table :users, force: true do |t|
    t.string :name
    t.integer :score
    t.timestamp :created_at
    t.date :created_on
  end

  ActiveRecord::Migration.create_table :posts, force: true do |t|
    t.references :user
    t.timestamp :created_at
  end
end

def create_redshift_tables
  ActiveRecord::Migration.verbose = false

  if ActiveRecord::Migration.table_exists?(:users)
    ActiveRecord::Migration.drop_table(:users, force: :cascade)
  end

  if ActiveRecord::Migration.table_exists?(:posts)
    ActiveRecord::Migration.drop_table(:posts, force: :cascade)
  end

  ActiveRecord::Migration.execute "CREATE TABLE users (id INT IDENTITY(1,1) PRIMARY KEY, name VARCHAR(255), score INT, created_at DATETIME, created_on DATE);"

  ActiveRecord::Migration.execute "CREATE TABLE posts (id INT IDENTITY(1,1) PRIMARY KEY, user_id INT REFERENCES users, created_at DATETIME);"
end

module TestDatabase
  def test_zeros_previous_scope
    create_user "2013-05-01"
    expected = {
      Date.parse("2013-05-01") => 0
    }
    assert_equal expected, User.where("id = 0").group_by_day(:created_at, range: Date.parse("2013-05-01")..Date.parse("2013-05-01 23:59:59 UTC")).count
  end

  def test_order_hour_of_day
    assert_equal 23, User.group_by_hour_of_day(:created_at).order("hour_of_day desc").count.keys.first
  end

  def test_order_hour_of_day_case
    assert_equal 23, User.group_by_hour_of_day(:created_at).order("hour_of_day DESC").count.keys.first
  end

  def test_order_hour_of_day_reverse
    skip if ActiveRecord::VERSION::MAJOR == 5
    assert_equal 23, User.group_by_hour_of_day(:created_at).reverse_order.count.keys.first
  end

  def test_order_hour_of_day_order_reverse
    skip if ActiveRecord::VERSION::MAJOR == 5
    assert_equal 0, User.group_by_hour_of_day(:created_at).order("hour_of_day desc").reverse_order.count.keys.first
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
    today = Date.today
    create_user today.to_s
    this_month = pt.parse(today.to_s).beginning_of_month
    last_month = this_month - 1.month
    expected = {
      last_month.to_date => 0,
      this_month.to_date => 1
    }
    assert_equal expected, User.group_by_month(:created_on, last: 2).count
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

  def test_quarter_and_last
    today = Date.today
    create_user today.to_s
    this_quarter = today.to_time.beginning_of_quarter
    last_quarter = this_quarter - 3.months
    expected = {
      last_quarter.to_date => 0,
      this_quarter.to_date => 1
    }
    assert_equal expected, User.group_by_quarter(:created_at, last: 2).count
  end

  def test_format_locale
    create_user "2014-10-01"
    assert_equal ({"Okt" => 1}), User.group_by_day(:created_at, format: "%b", locale: :de).count
  end

  def test_format_locale_by_symbol
    create_user "2014-10-01"
    assert_equal ({"Okt  1, 2014" => 1}), User.group_by_day(:created_at, format: :special, locale: :de).count
  end

  def test_format_locale_global
    create_user "2014-10-01"
    I18n.locale = :de
    assert_equal ({"Okt" => 1}), User.group_by_day(:created_at, format: "%b").count
  ensure
    I18n.locale = :en
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
    assert_raises(RuntimeError) { User.group_by_day(:created_at).count }
  ensure
    User.default_timezone = :utc
  end

  # Brasilia Summer Time

  def test_brasilia_summer_time
    # must parse and convert to UTC for ActiveRecord 3.1
    create_user(brasilia.parse("2014-10-19 02:00:00").utc.to_s)
    create_user(brasilia.parse("2014-10-20 02:00:00").utc.to_s)
    expected = {
      Date.parse("2014-10-19") => 1,
      Date.parse("2014-10-20") => 1
    }
    assert_equal expected, User.group_by_day(:created_at, time_zone: "Brasilia").count
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

  def test_using_unlisted_calculation_method_returns_new_series_instance
    assert_instance_of Groupdate::Series, User.group_by_day(:created_at).unlisted_calculation
  end

  def test_using_listed_but_undefined_custom_calculation_method_raises_error
    assert_raises(NoMethodError) do
      User.group_by_day(:created_at).undefined_calculation
    end
  end

  private

  def call_method(method, field, options)
    User.group_by_period(method, field, options).count
  end

  def create_user(created_at, score = 1)
    user =
      User.create!(
        name: "Andrew",
        score: score,
        created_at: created_at ? utc.parse(created_at) : nil,
        created_on: created_at ? Date.parse(created_at) : nil
      )

    # hack for Redshift adapter, which doesn't return id on creation...
    user = User.last if user.id.nil?

    # hack for MySQL & Redshift adapters
    user.update_attributes(created_at: nil, created_on: nil) if created_at.nil? && is_redshift?

    user
  end

  def is_redshift?
    ActiveRecord::Base.connection.adapter_name == "Redshift"
  end

  def teardown
    User.delete_all
  end

  def enumerable_test?
    false
  end
end

module TestGroupdate
  def setup
    Groupdate.week_start = :sun
  end

  # second

  def test_second_end_of_second
    if enumerable_test? || ActiveRecord::Base.connection.adapter_name == "Mysql2"
      skip # no millisecond precision
    else
      assert_result_time :second, "2013-05-03 00:00:00 UTC", "2013-05-03 00:00:00.999"
    end
  end

  def test_second_start_of_second
    assert_result_time :second, "2013-05-03 00:00:01 UTC", "2013-05-03 00:00:01.000"
  end

  # minute

  def test_minute_end_of_minute
    assert_result_time :minute, "2013-05-03 00:00:00 UTC", "2013-05-03 00:00:59"
  end

  def test_minute_start_of_minute
    assert_result_time :minute, "2013-05-03 00:01:00 UTC", "2013-05-03 00:01:00"
  end

  # hour

  def test_hour_end_of_hour
    assert_result_time :hour, "2013-05-03 00:00:00 UTC", "2013-05-03 00:59:59"
  end

  def test_hour_start_of_hour
    assert_result_time :hour, "2013-05-03 01:00:00 UTC", "2013-05-03 01:00:00"
  end

  # day

  def test_day_end_of_day
    assert_result_date :day, "2013-05-03", "2013-05-03 23:59:59"
  end

  def test_day_start_of_day
    assert_result_date :day, "2013-05-04", "2013-05-04 00:00:00"
  end

  def test_day_end_of_day_with_time_zone
    assert_result_date :day, "2013-05-02", "2013-05-03 06:59:59", true
  end

  def test_day_start_of_day_with_time_zone
    assert_result_date :day, "2013-05-03", "2013-05-03 07:00:00", true
  end

  # day hour starts at 2 am

  def test_test_day_end_of_day_day_start_2am
    assert_result_date :day, "2013-05-03", "2013-05-04 01:59:59", false, day_start: 2
  end

  def test_test_day_start_of_day_day_start_2am
    assert_result_date :day, "2013-05-03", "2013-05-03 02:00:00", false, day_start: 2
  end

  def test_test_day_end_of_day_with_time_zone_day_start_2am
    assert_result_date :day, "2013-05-03", "2013-05-04 07:59:59", true, day_start: 2
  end

  def test_test_day_start_of_day_with_time_zone_day_start_2am
    assert_result_date :day, "2013-05-03", "2013-05-03 09:00:00", true, day_start: 2
  end

  # week

  def test_week_end_of_week
    assert_result_date :week, "2013-03-17", "2013-03-23 23:59:59"
  end

  def test_week_start_of_week
    assert_result_date :week, "2013-03-24", "2013-03-24 00:00:00"
  end

  def test_week_end_of_week_with_time_zone
    assert_result_date :week, "2013-03-10", "2013-03-17 06:59:59", true
  end

  def test_week_start_of_week_with_time_zone
    assert_result_date :week, "2013-03-17", "2013-03-17 07:00:00", true
  end

  # week starting on monday

  def test_week_end_of_week_mon
    assert_result_date :week, "2013-03-18", "2013-03-24 23:59:59", false, week_start: :mon
  end

  def test_week_start_of_week_mon
    assert_result_date :week, "2013-03-25", "2013-03-25 00:00:00", false, week_start: :mon
  end

  def test_week_end_of_week_with_time_zone_mon
    assert_result_date :week, "2013-03-11", "2013-03-18 06:59:59", true, week_start: :mon
  end

  def test_week_start_of_week_with_time_zone_mon
    assert_result_date :week, "2013-03-18", "2013-03-18 07:00:00", true, week_start: :mon
  end

  # week starting on saturday

  def test_week_end_of_week_sat
    assert_result_date :week, "2013-03-16", "2013-03-22 23:59:59", false, week_start: :sat
  end

  def test_week_start_of_week_sat
    assert_result_date :week, "2013-03-23", "2013-03-23 00:00:00", false, week_start: :sat
  end

  def test_week_end_of_week_with_time_zone_sat
    assert_result_date :week, "2013-03-09", "2013-03-16 06:59:59", true, week_start: :sat
  end

  def test_week_start_of_week_with_time_zone_sat
    assert_result_date :week, "2013-03-16", "2013-03-16 07:00:00", true, week_start: :sat
  end

  # week starting at 2am

  def test_week_end_of_week_day_start_2am
    assert_result_date :week, "2013-03-17", "2013-03-24 01:59:59", false, day_start: 2
  end

  def test_week_start_of_week_day_start_2am
    assert_result_date :week, "2013-03-17", "2013-03-17 02:00:00", false, day_start: 2
  end

  def test_week_end_of_week_day_with_time_zone_start_2am
    assert_result_date :week, "2013-03-17", "2013-03-24 08:59:59", true, day_start: 2
  end

  def test_week_start_of_week_day_with_time_zone_start_2am
    assert_result_date :week, "2013-03-17", "2013-03-17 09:00:00", true, day_start: 2
  end

  # month

  def test_month_end_of_month
    assert_result_date :month, "2013-05-01", "2013-05-31 23:59:59"
  end

  def test_month_start_of_month
    assert_result_date :month, "2013-06-01", "2013-06-01 00:00:00"
  end

  def test_month_end_of_month_with_time_zone
    assert_result_date :month, "2013-05-01", "2013-06-01 06:59:59", true
  end

  def test_month_start_of_month_with_time_zone
    assert_result_date :month, "2013-06-01", "2013-06-01 07:00:00", true
  end

  # month starts at 2am

  def test_month_end_of_month_day_start_2am
    assert_result_date :month, "2013-03-01", "2013-04-01 01:59:59", false, day_start: 2
  end

  def test_month_start_of_month_day_start_2am
    assert_result_date :month, "2013-03-01", "2013-03-01 02:00:00", false, day_start: 2
  end

  def test_month_end_of_month_with_time_zone_day_start_2am
    assert_result_date :month, "2013-03-01", "2013-04-01 08:59:59", true, day_start: 2
  end

  def test_month_start_of_month_with_time_zone_day_start_2am
    assert_result_date :month, "2013-03-01", "2013-03-01 10:00:00", true, day_start: 2
  end

  # quarter

  def test_quarter_end_of_quarter
    assert_result_date :quarter, "2013-04-01", "2013-06-30 23:59:59"
  end

  def test_quarter_start_of_quarter
    assert_result_date :quarter, "2013-04-01", "2013-04-01 00:00:00"
  end

  def test_quarter_end_of_quarter_with_time_zone
    assert_result_date :quarter, "2013-04-01", "2013-07-01 06:59:59", true
  end

  def test_quarter_start_of_quarter_with_time_zone
    assert_result_date :quarter, "2013-04-01", "2013-04-01 07:00:00", true
  end

  # quarter starts at 2am

  def test_quarter_end_of_quarter_day_start_2am
    assert_result_date :quarter, "2013-04-01", "2013-07-01 01:59:59", false, day_start: 2
  end

  def test_quarter_start_of_quarter_day_start_2am
    assert_result_date :quarter, "2013-04-01", "2013-04-01 02:00:00", false, day_start: 2
  end

  def test_quarter_end_of_quarter_with_time_zone_day_start_2am
    assert_result_date :quarter, "2013-01-01", "2013-04-01 08:59:59", true, day_start: 2
  end

  def test_quarter_start_of_quarter_with_time_zone_day_start_2am
    assert_result_date :quarter, "2013-01-01", "2013-01-01 10:00:00", true, day_start: 2
  end

  # year

  def test_year_end_of_year
    assert_result_date :year, "2013-01-01", "2013-12-31 23:59:59"
  end

  def test_year_start_of_year
    assert_result_date :year, "2014-01-01", "2014-01-01 00:00:00"
  end

  def test_year_end_of_year_with_time_zone
    assert_result_date :year, "2013-01-01", "2014-01-01 07:59:59", true
  end

  def test_year_start_of_year_with_time_zone
    assert_result_date :year, "2014-01-01", "2014-01-01 08:00:00", true
  end

  # year starts at 2am

  def test_year_end_of_year_day_start_2am
    assert_result_date :year, "2013-01-01", "2014-01-01 01:59:59", false, day_start: 2
  end

  def test_year_start_of_year_day_start_2am
    assert_result_date :year, "2013-01-01", "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_year_end_of_year_with_time_zone_day_start_2am
    assert_result_date :year, "2013-01-01", "2014-01-01 09:59:59", true, day_start: 2
  end

  def test_year_start_of_year_with_time_zone_day_start_2am
    assert_result_date :year, "2013-01-01", "2013-01-01 10:00:00", true, day_start: 2
  end

  # hour of day

  def test_hour_of_day_end_of_hour
    assert_result :hour_of_day, 0, "2013-01-01 00:59:59"
  end

  def test_hour_of_day_start_of_hour
    assert_result :hour_of_day, 1, "2013-01-01 01:00:00"
  end

  def test_hour_of_day_end_of_hour_with_time_zone
    assert_result :hour_of_day, 0, "2013-01-01 08:59:59", true
  end

  def test_hour_of_day_start_of_hour_with_time_zone
    assert_result :hour_of_day, 1, "2013-01-01 09:00:00", true
  end

  # hour of day starts at 2am

  def test_hour_of_day_end_of_day_day_start_2am
    assert_result :hour_of_day, 23, "2013-01-01 01:59:59", false, day_start: 2
  end

  def test_hour_of_day_start_of_day_day_start_2am
    assert_result :hour_of_day, 0, "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_hour_of_day_end_of_day_with_time_zone_day_start_2am
    assert_result :hour_of_day, 23, "2013-01-01 09:59:59", true, day_start: 2
  end

  def test_hour_of_day_start_of_day_with_time_zone_day_start_2am
    assert_result :hour_of_day, 0, "2013-01-01 10:00:00", true, day_start: 2
  end

  # day of week

  def test_day_of_week_end_of_day
    assert_result :day_of_week, 2, "2013-01-01 23:59:59"
  end

  def test_day_of_week_start_of_day
    assert_result :day_of_week, 3, "2013-01-02 00:00:00"
  end

  def test_day_of_week_end_of_week_with_time_zone
    assert_result :day_of_week, 2, "2013-01-02 07:59:59", true
  end

  def test_day_of_week_start_of_week_with_time_zone
    assert_result :day_of_week, 3, "2013-01-02 08:00:00", true
  end

  # day of week starts at 2am

  def test_day_of_week_end_of_day_day_start_2am
    assert_result :day_of_week, 3, "2013-01-03 01:59:59", false, day_start: 2
  end

  def test_day_of_week_start_of_day_day_start_2am
    assert_result :day_of_week, 3, "2013-01-02 02:00:00", false, day_start: 2
  end

  def test_day_of_week_end_of_day_with_time_zone_day_start_2am
    assert_result :day_of_week, 3, "2013-01-03 09:59:59", true, day_start: 2
  end

  def test_day_of_week_start_of_day_with_time_zone_day_start_2am
    assert_result :day_of_week, 3, "2013-01-02 10:00:00", true, day_start: 2
  end

  # day of month

  def test_day_of_month_end_of_day
    assert_result :day_of_month, 31, "2013-01-31 23:59:59"
  end

  def test_day_of_month_end_of_day_feb_leap_year
    assert_result :day_of_month, 29, "2012-02-29 23:59:59"
  end

  def test_day_of_month_start_of_day
    assert_result :day_of_month, 3, "2013-01-03 00:00:00"
  end

  def test_day_of_month_end_of_day_with_time_zone
    assert_result :day_of_month, 31, "2013-02-01 07:59:59", true
  end

  def test_day_of_month_start_of_day_with_time_zone
    assert_result :day_of_month, 1, "2013-01-01 08:00:00", true
  end

  # day of month starts at 2am

  def test_day_of_month_end_of_day_day_start_2am
    assert_result :day_of_month, 31, "2013-01-01 01:59:59", false, day_start: 2
  end

  def test_day_of_month_start_of_day_day_start_2am
    assert_result :day_of_month, 1, "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_day_of_month_end_of_day_with_time_zone_day_start_2am
    assert_result :day_of_month, 31, "2013-01-01 09:59:59", true, day_start: 2
  end

  def test_day_of_month_start_of_day_with_time_zone_day_start_2am
    assert_result :day_of_month, 1, "2013-01-01 10:00:00", true, day_start: 2
  end

  # month of year

  def test_month_of_year_end_of_month
    assert_result :month_of_year, 1, "2013-01-31 23:59:59"
  end

  def test_month_of_year_start_of_month
    assert_result :month_of_year, 1, "2013-01-01 00:00:00"
  end

  def test_month_of_year_end_of_month_with_time_zone
    assert_result :month_of_year, 1, "2013-02-01 07:59:59", true
  end

  def test_month_of_year_start_of_month_with_time_zone
    assert_result :month_of_year, 1, "2013-01-01 08:00:00", true
  end

  # month of year starts at 2am

  def test_month_of_year_end_of_month_day_start_2am
    assert_result :month_of_year, 12, "2013-01-01 01:59:59", false, day_start: 2
  end

  def test_month_of_year_start_of_month_day_start_2am
    assert_result :month_of_year, 1, "2013-01-01 02:00:00", false, day_start: 2
  end

  def test_month_of_year_end_of_month_with_time_zone_day_start_2am
    assert_result :month_of_year, 12, "2013-01-01 09:59:59", true, day_start: 2
  end

  def test_month_of_year_start_of_month_with_time_zone_day_start_2am
    assert_result :month_of_year, 1, "2013-01-01 10:00:00", true, day_start: 2
  end

  # zeros

  def test_zeros_second
    assert_zeros :second, "2013-05-01 00:00:01 UTC", ["2013-05-01 00:00:00 UTC", "2013-05-01 00:00:01 UTC", "2013-05-01 00:00:02 UTC"], "2013-05-01 00:00:00.999 UTC", "2013-05-01 00:00:02 UTC"
  end

  def test_zeros_minute
    assert_zeros :minute, "2013-05-01 00:01:00 UTC", ["2013-05-01 00:00:00 UTC", "2013-05-01 00:01:00 UTC", "2013-05-01 00:02:00 UTC"], "2013-05-01 00:00:59 UTC", "2013-05-01 00:02:00 UTC"
  end

  def test_zeros_hour
    assert_zeros :hour, "2013-05-01 04:01:01 UTC", ["2013-05-01 03:00:00 UTC", "2013-05-01 04:00:00 UTC", "2013-05-01 05:00:00 UTC"], "2013-05-01 03:59:59 UTC", "2013-05-01 05:00:00 UTC"
  end

  def test_zeros_day
    assert_zeros_date :day, "2013-05-01 20:00:00 UTC", ["2013-04-30", "2013-05-01", "2013-05-02"], "2013-04-30 00:00:00 UTC", "2013-05-02 23:59:59 UTC"
  end

  def test_zeros_day_time_zone
    assert_zeros_date :day, "2013-05-01 20:00:00 PDT", ["2013-04-30", "2013-05-01", "2013-05-02"], "2013-04-30 00:00:00 PDT", "2013-05-02 23:59:59 PDT", true
  end

  def test_zeros_week
    assert_zeros_date :week, "2013-05-01 20:00:00 UTC", ["2013-04-21", "2013-04-28", "2013-05-05"], "2013-04-27 23:59:59 UTC", "2013-05-11 23:59:59 UTC"
  end

  def test_zeros_week_time_zone
    assert_zeros_date :week, "2013-05-01 20:00:00 PDT", ["2013-04-21", "2013-04-28", "2013-05-05"], "2013-04-27 23:59:59 PDT", "2013-05-11 23:59:59 PDT", true
  end

  def test_zeros_week_mon
    assert_zeros_date :week, "2013-05-01 20:00:00 UTC", ["2013-04-22", "2013-04-29", "2013-05-06"], "2013-04-27 23:59:59 UTC", "2013-05-11 23:59:59 UTC", false, week_start: :mon
  end

  def test_zeros_week_time_zone_mon
    assert_zeros_date :week, "2013-05-01 20:00:00 PDT", ["2013-04-22", "2013-04-29", "2013-05-06"], "2013-04-27 23:59:59 PDT", "2013-05-11 23:59:59 PDT", true, week_start: :mon
  end

  def test_zeros_week_sat
    assert_zeros_date :week, "2013-05-01 20:00:00 UTC", ["2013-04-20", "2013-04-27", "2013-05-04"], "2013-04-26 23:59:59 UTC", "2013-05-10 23:59:59 UTC", false, week_start: :sat
  end

  def test_zeros_week_time_zone_sat
    assert_zeros_date :week, "2013-05-01 20:00:00 PDT", ["2013-04-20", "2013-04-27", "2013-05-04"], "2013-04-26 23:59:59 PDT", "2013-05-10 23:59:59 PDT", true, week_start: :sat
  end

  def test_zeros_month
    assert_zeros_date :month, "2013-04-16 20:00:00 UTC", ["2013-03-01", "2013-04-01", "2013-05-01"], "2013-03-01", "2013-05-31 23:59:59 UTC"
  end

  def test_zeros_month_time_zone
    assert_zeros_date :month, "2013-04-16 20:00:00 PDT", ["2013-03-01", "2013-04-01", "2013-05-01"], "2013-03-01 00:00:00 PST", "2013-05-31 23:59:59 PDT", true
  end

  def test_zeros_quarter
    assert_zeros_date :quarter, "2013-04-16 20:00:00 UTC", ["2013-01-01", "2013-04-01", "2013-07-01"], "2013-01-01", "2013-09-30 23:59:59 UTC"
  end

  def test_zeros_quarter_time_zone
    assert_zeros_date :quarter, "2013-04-16 20:00:00 PDT", ["2013-01-01", "2013-04-01", "2013-07-01"], "2013-01-01 00:00:00 PST", "2013-09-30 23:59:59 PDT", true
  end

  def test_zeros_year
    assert_zeros_date :year, "2013-04-16 20:00:00 UTC", ["2012-01-01", "2013-01-01", "2014-01-01"], "2012-01-01", "2014-12-31 23:59:59 UTC"
  end

  def test_zeros_year_time_zone
    assert_zeros_date :year, "2013-04-16 20:00:00 PDT", ["2012-01-01 00:00:00 PST", "2013-01-01 00:00:00 PST", "2014-01-01 00:00:00 PST"], "2012-01-01 00:00:00 PST", "2014-12-31 23:59:59 PST", true
  end

  def test_zeros_day_of_week
    create_user "2013-05-01"
    expected = {}
    7.times do |n|
      expected[n] = n == 3 ? 1 : 0
    end
    assert_equal expected, call_method(:day_of_week, :created_at, {series: true})
  end

  def test_zeros_hour_of_day
    create_user "2013-05-01 20:00:00 UTC"
    expected = {}
    24.times do |n|
      expected[n] = n == 20 ? 1 : 0
    end
    assert_equal expected, call_method(:hour_of_day, :created_at, {series: true})
  end

  def test_zeros_day_of_month
    create_user "1978-12-18"
    expected = {}
    (1..31).each do |n|
      expected[n] = n == 18 ? 1 : 0
    end
    assert_equal expected, call_method(:day_of_month, :created_at, {series: true})
  end

  def test_zeros_month_of_year
    create_user "2013-05-01"
    expected = {}
    (1..12).each do |n|
      expected[n] = n == 5 ? 1 : 0
    end
    assert_equal expected, call_method(:month_of_year, :created_at, {series: true})
  end

  def test_zeros_excludes_end
    create_user "2013-05-02"
    expected = {
      Date.parse("2013-05-01") => 0
    }
    assert_equal expected, call_method(:day, :created_at, range: Date.parse("2013-05-01")...Date.parse("2013-05-02"), series: true)
  end

  def test_zeros_datetime
    create_user "2013-05-01"
    expected = {
      Date.parse("2013-05-01") => 1
    }
    assert_equal expected, call_method(:day, :created_at, range: DateTime.parse("2013-05-01")..DateTime.parse("2013-05-01"), series: true)
  end

  def test_zeros_null_value
    create_user nil
    assert_equal 0, call_method(:hour_of_day, :created_at, range: true, series: true)[0]
  end

  def test_zeroes_range_true
    create_user "2013-05-01"
    create_user "2013-05-03"
    expected = {
      Date.parse("2013-05-01") => 1,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, call_method(:day, :created_at, range: true, series: true)
  end

  # week_start

  def test_week_start
    Groupdate.week_start = :mon
    assert_result_date :week, "2013-03-18", "2013-03-24 23:59:59"
  end

  def test_week_start_and_start_option
    Groupdate.week_start = :mon
    assert_result_date :week, "2013-03-16", "2013-03-22 23:59:59", false, week_start: :sat
  end

  # misc

  def test_order_hour_of_day_reverse_option
    assert_equal 23, call_method(:hour_of_day, :created_at, reverse: true, series: true).keys.first
  end

  def test_time_zone
    create_user "2013-05-01"
    time_zone = "Pacific Time (US & Canada)"
    assert_equal time_zone, call_method(:hour, :created_at, time_zone: time_zone).keys.first.time_zone.name
  end

  def test_format_day
    create_user "2014-03-01"
    assert_format :day, "March 1, 2014", "%B %-e, %Y"
  end

  def test_format_month
    create_user "2014-03-01"
    assert_format :month, "March 2014", "%B %Y"
  end

  def test_format_quarter
    create_user "2014-03-05"
    assert_format :quarter, "January 1, 2014", "%B %-e, %Y"
  end

  def test_format_year
    create_user "2014-03-01"
    assert_format :year, "2014", "%Y"
  end

  def test_format_hour_of_day
    create_user "2014-03-01"
    assert_format :hour_of_day, "12 am", "%-l %P"
  end

  def test_format_hour_of_day_day_start
    create_user "2014-03-01"
    assert_format :hour_of_day, "12 am", "%-l %P", day_start: 2
  end

  def test_format_day_of_week
    create_user "2014-03-01"
    assert_format :day_of_week, "Sat", "%a"
  end

  def test_format_day_of_week_day_start
    create_user "2014-03-01"
    assert_format :day_of_week, "Fri", "%a", day_start: 2
  end

  def test_format_day_of_week_week_start
    create_user "2014-03-01"
    assert_format :day_of_week, "Sat", "%a", week_start: :mon
  end

  def test_format_day_of_month
    create_user "2014-03-01"
    assert_format :day_of_month, " 1", "%e"
  end

  def test_format_month_of_year
    create_user "2014-01-01"
    assert_format :month_of_year, "Jan", "%b"
  end

  # date column

  def test_date_column
    expected = {
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, result(:day, "2013-05-03", false)
  end

  def test_date_column_with_time_zone
    expected = {
      Date.parse("2013-05-02") => 1
    }
    assert_equal expected, result(:day, "2013-05-03", true)
  end

  def test_date_column_with_time_zone_false
    Time.zone = pt
    create_user "2013-05-03"
    expected = {
      Date.parse("2013-05-03") => 1
    }
    assert_equal expected, call_method(:day, :created_at, time_zone: false)
  ensure
    Time.zone = nil
  end

  # date range

  def test_date_range
    ENV["TZ"] = "Europe/Oslo"
    expected = {
      Date.parse("2013-05-01") => 0,
      Date.parse("2013-05-02") => 0,
      Date.parse("2013-05-03") => 0
    }
    assert_equal expected, call_method(:day, :created_at, series: true, range: Date.parse("2013-05-01")..Date.parse("2013-05-03"))
  ensure
    ENV["TZ"] = "UTC"
  end

  def test_date_range_exclude_end
    ENV["TZ"] = "Europe/Oslo"
    expected = {
      Date.parse("2013-05-01") => 0,
      Date.parse("2013-05-02") => 0
    }
    assert_equal expected, call_method(:day, :created_at, series: true, range: Date.parse("2013-05-01")...Date.parse("2013-05-03"))
  ensure
    ENV["TZ"] = "UTC"
  end

  # day start

  def test_day_start_decimal_end_of_day
    assert_result_date :day, "2013-05-03", "2013-05-04 02:29:59", false, day_start: 2.5
  end

  def test_day_start_decimal_start_of_day
    assert_result_date :day, "2013-05-03", "2013-05-03 02:30:00", false, day_start: 2.5
  end

  private

  # helpers

  def assert_format(method, expected, format, options = {})
    assert_equal({expected => 1}, call_method(method, :created_at, options.merge(format: format, series: false)))
  end

  def assert_result_time(method, expected, time_str, time_zone = false, options = {})
    expected = {utc.parse(expected).in_time_zone(time_zone ? "Pacific Time (US & Canada)" : utc) => 1}
    assert_equal expected, result(method, time_str, time_zone, options)
  end

  def assert_result_date(method, expected_str, time_str, time_zone = false, options = {})
    create_user time_str
    expected = {Date.parse(expected_str) => 1}
    assert_equal expected, call_method(method, :created_at, options.merge(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil))
    expected = {(time_zone ? pt : utc).parse(expected_str) + options[:day_start].to_f.hours => 1}
    assert_equal expected, call_method(method, :created_at, options.merge(dates: false, time_zone: time_zone ? "Pacific Time (US & Canada)" : nil))
    # assert_equal expected, call_method(method, :created_on, options.merge(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil))
  end

  def assert_result(method, expected, time_str, time_zone = false, options = {})
    assert_equal 1, result(method, time_str, time_zone, options)[expected]
  end

  def result(method, time_str, time_zone = false, options = {})
    create_user time_str
    call_method(method, :created_at, options.merge(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil))
  end

  def assert_zeros(method, created_at, keys, range_start, range_end, time_zone = nil, options = {})
    create_user created_at
    expected = {}
    keys.each_with_index do |key, i|
      expected[utc.parse(key).in_time_zone(time_zone ? "Pacific Time (US & Canada)" : utc)] = i == 1 ? 1 : 0
    end
    assert_equal expected, call_method(method, :created_at, options.merge(series: true, time_zone: time_zone ? "Pacific Time (US & Canada)" : nil, range: Time.parse(range_start)..Time.parse(range_end)))
  end

  def assert_zeros_date(method, created_at, keys, range_start, range_end, time_zone = nil, options = {})
    create_user created_at
    expected = {}
    keys.each_with_index do |key, i|
      expected[Date.parse(key)] = i == 1 ? 1 : 0
    end
    assert_equal expected, call_method(method, :created_at, options.merge(series: true, time_zone: time_zone ? "Pacific Time (US & Canada)" : nil, range: Time.parse(range_start)..Time.parse(range_end)))
  end

  def this_quarters_month
    Time.now.beginning_of_quarter.month
  end

  def this_year
    Time.now.year
  end

  def this_month
    Time.now.month
  end

  def utc
    ActiveSupport::TimeZone["UTC"]
  end

  def pt
    ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
  end

  def brasilia
    ActiveSupport::TimeZone["Brasilia"]
  end
end
