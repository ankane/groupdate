require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "logger"

# TODO determine why this is necessary
if RUBY_PLATFORM == "java"
  ENV["TZ"] = "UTC"
end

# for debugging
# ActiveRecord::Base.logger = Logger.new(STDOUT)

# rails does this in activerecord/lib/active_record/railtie.rb
ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true

class User < ActiveRecord::Base
end

# migrations
%w(postgresql mysql2).each do |adapter|
  ActiveRecord::Base.establish_connection :adapter => adapter, :database => "groupdate_test", :username => adapter == "mysql2" ? "root" : nil

  ActiveRecord::Migration.create_table :users, :force => true do |t|
    t.string :name
    t.integer :score
    t.timestamps
  end
end

module TestGroupdate

  def setup
    Groupdate.week_start = :sun
  end

  # second

  def test_second_end_of_second
    assert_result_time :second, "2013-05-03 00:00:00 UTC", "2013-05-03 00:00:00.999"
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
    assert_result_time :day, "2013-05-03 00:00:00 UTC", "2013-05-03 23:59:59"
  end

  def test_day_start_of_day
    assert_result_time :day, "2013-05-04 00:00:00 UTC", "2013-05-04 00:00:00"
  end

  def test_day_end_of_day_with_time_zone
    assert_result_time :day, "2013-05-02 00:00:00 PDT", "2013-05-03 06:59:59", true
  end

  def test_day_start_of_day_with_time_zone
    assert_result_time :day, "2013-05-03 00:00:00 PDT", "2013-05-03 07:00:00", true
  end

  # day hour starts at 2 am

  def test_test_day_end_of_day_day_start_2am
    assert_result_time :day, "2013-05-03 02:00:00 UTC", "2013-05-04 01:59:59", false, :day_start => 2
  end

  def test_test_day_start_of_day_day_start_2am
    assert_result_time :day, "2013-05-03 02:00:00 UTC", "2013-05-03 02:00:00", false, :day_start => 2
  end

  def test_test_day_end_of_day_with_time_zone_day_start_2am
    assert_result_time :day, "2013-05-03 02:00:00 PDT", "2013-05-04 07:59:59", true, :day_start => 2
  end

  def test_test_day_start_of_day_with_time_zone_day_start_2am
    assert_result_time :day, "2013-05-03 02:00:00 PDT", "2013-05-03 09:00:00", true, :day_start => 2
  end

  # week

  def test_week_end_of_week
    assert_result_time :week, "2013-03-17 00:00:00 UTC", "2013-03-23 23:59:59"
  end

  def test_week_start_of_week
    assert_result_time :week, "2013-03-24 00:00:00 UTC", "2013-03-24 00:00:00"
  end

  def test_week_end_of_week_with_time_zone
    assert_result_time :week, "2013-03-10 00:00:00 PST", "2013-03-17 06:59:59", true
  end

  def test_week_start_of_week_with_time_zone
    assert_result_time :week, "2013-03-17 00:00:00 PDT", "2013-03-17 07:00:00", true
  end

  # week starting on monday

  def test_week_end_of_week_mon
    assert_result_time :week, "2013-03-18 00:00:00 UTC", "2013-03-24 23:59:59", false, week_start: :mon
  end

  def test_week_start_of_week_mon
    assert_result_time :week, "2013-03-25 00:00:00 UTC", "2013-03-25 00:00:00", false, week_start: :mon
  end

  def test_week_end_of_week_with_time_zone_mon
    assert_result_time :week, "2013-03-11 00:00:00 PDT", "2013-03-18 06:59:59", true, week_start: :mon
  end

  def test_week_start_of_week_with_time_zone_mon
    assert_result_time :week, "2013-03-18 00:00:00 PDT", "2013-03-18 07:00:00", true, week_start: :mon
  end

  # week starting on saturday

  def test_week_end_of_week_sat
    assert_result_time :week, "2013-03-16 00:00:00 UTC", "2013-03-22 23:59:59", false, week_start: :sat
  end

  def test_week_start_of_week_sat
    assert_result_time :week, "2013-03-23 00:00:00 UTC", "2013-03-23 00:00:00", false, week_start: :sat
  end

  def test_week_end_of_week_with_time_zone_sat
    assert_result_time :week, "2013-03-09 00:00:00 PST", "2013-03-16 06:59:59", true, week_start: :sat
  end

  def test_week_start_of_week_with_time_zone_sat
    assert_result_time :week, "2013-03-16 00:00:00 PDT", "2013-03-16 07:00:00", true, week_start: :sat
  end

  # week starting at 2am

  def test_week_end_of_week_day_start_2am
    assert_result_time :week, "2013-03-17 02:00:00 UTC", "2013-03-24 01:59:59", false, :day_start => 2
  end

  def test_week_start_of_week_day_start_2am
    assert_result_time :week, "2013-03-17 02:00:00 UTC", "2013-03-17 02:00:00", false, :day_start => 2
  end

  def test_week_end_of_week_day_with_time_zone_start_2am
    assert_result_time :week, "2013-03-17 02:00:00 PDT", "2013-03-24 08:59:59", true, :day_start => 2
  end

  def test_week_start_of_week_day_with_time_zone_start_2am
    assert_result_time :week, "2013-03-17 02:00:00 PDT", "2013-03-17 09:00:00", true, :day_start => 2
  end

  # month

  def test_month_end_of_month
    assert_result_time :month, "2013-05-01 00:00:00 UTC", "2013-05-31 23:59:59"
  end

  def test_month_start_of_month
    assert_result_time :month, "2013-06-01 00:00:00 UTC", "2013-06-01 00:00:00"
  end

  def test_month_end_of_month_with_time_zone
    assert_result_time :month, "2013-05-01 00:00:00 PDT", "2013-06-01 06:59:59", true
  end

  def test_month_start_of_month_with_time_zone
    assert_result_time :month, "2013-06-01 00:00:00 PDT", "2013-06-01 07:00:00", true
  end

  # month starts at 2am

  def test_month_end_of_month_day_start_2am
    assert_result_time :month, "2013-03-01 02:00:00 UTC", "2013-04-01 01:59:59", false, :day_start => 2
  end

  def test_month_start_of_month_day_start_2am
    assert_result_time :month, "2013-03-01 02:00:00 UTC", "2013-03-01 02:00:00", false, :day_start => 2
  end

  def test_month_end_of_month_with_time_zone_day_start_2am
    assert_result_time :month, "2013-03-01 02:00:00 PST", "2013-04-01 08:59:59", true, :day_start => 2
  end

  def test_month_start_of_month_with_time_zone_day_start_2am
    assert_result_time :month, "2013-03-01 02:00:00 PST", "2013-03-01 10:00:00", true, :day_start => 2
  end

  # year

  def test_year_end_of_year
    assert_result_time :year, "2013-01-01 00:00:00 UTC", "2013-12-31 23:59:59"
  end

  def test_year_start_of_year
    assert_result_time :year, "2014-01-01 00:00:00 UTC", "2014-01-01 00:00:00"
  end

  def test_year_end_of_year_with_time_zone
    assert_result_time :year, "2013-01-01 00:00:00 PST", "2014-01-01 07:59:59", true
  end

  def test_year_start_of_year_with_time_zone
    assert_result_time :year, "2014-01-01 00:00:00 PST", "2014-01-01 08:00:00", true
  end

  # year starts at 2am

  def test_year_end_of_year_day_start_2am
    assert_result_time :year, "2013-01-01 02:00:00 UTC", "2014-01-01 01:59:59", false, :day_start => 2
  end

  def test_year_start_of_year_day_start_2am
    assert_result_time :year, "2013-01-01 02:00:00 UTC", "2013-01-01 02:00:00", false, :day_start => 2
  end

  def test_year_end_of_year_with_time_zone_day_start_2am
    assert_result_time :year, "2013-01-01 02:00:00 PST", "2014-01-01 09:59:59", true, :day_start => 2
  end

  def test_year_start_of_year_with_time_zone_day_start_2am
    assert_result_time :year, "2013-01-01 02:00:00 PST", "2013-01-01 10:00:00", true, :day_start => 2
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
    assert_result :hour_of_day, 23, "2013-01-01 01:59:59", false, :day_start => 2
  end

  def test_hour_of_day_start_of_day_day_start_2am
    assert_result :hour_of_day, 0, "2013-01-01 02:00:00", false, :day_start => 2
  end

  def test_hour_of_day_end_of_day_with_time_zone_day_start_2am
    assert_result :hour_of_day, 23, "2013-01-01 09:59:59", true, :day_start => 2
  end

  def test_hour_of_day_start_of_day_with_time_zone_day_start_2am
    assert_result :hour_of_day, 0, "2013-01-01 10:00:00", true, :day_start => 2
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
    assert_result :day_of_week, 3, "2013-01-03 01:59:59", false, :day_start => 2
  end

  def test_day_of_week_start_of_day_day_start_2am
    assert_result :day_of_week, 3, "2013-01-02 02:00:00", false, :day_start => 2
  end

  def test_day_of_week_end_of_day_with_time_zone_day_start_2am
    assert_result :day_of_week, 3, "2013-01-03 09:59:59", true, :day_start => 2
  end

  def test_day_of_week_start_of_day_with_time_zone_day_start_2am
    assert_result :day_of_week, 3, "2013-01-02 10:00:00", true, :day_start => 2
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
    assert_zeros :day, "2013-05-01 20:00:00 UTC", ["2013-04-30 00:00:00 UTC", "2013-05-01 00:00:00 UTC", "2013-05-02 00:00:00 UTC"], "2013-04-30 00:00:00 UTC", "2013-05-02 23:59:59 UTC"
  end

  def test_zeros_day_time_zone
    assert_zeros :day, "2013-05-01 20:00:00 PDT", ["2013-04-30 00:00:00 PDT", "2013-05-01 00:00:00 PDT", "2013-05-02 00:00:00 PDT"], "2013-04-30 00:00:00 PDT", "2013-05-02 23:59:59 PDT", true
  end

  def test_zeros_week
    assert_zeros :week, "2013-05-01 20:00:00 UTC", ["2013-04-21 00:00:00 UTC", "2013-04-28 00:00:00 UTC", "2013-05-05 00:00:00 UTC"], "2013-04-27 23:59:59 UTC", "2013-05-11 23:59:59 UTC"
  end

  def test_zeros_week_time_zone
    assert_zeros :week, "2013-05-01 20:00:00 PDT", ["2013-04-21 00:00:00 PDT", "2013-04-28 00:00:00 PDT", "2013-05-05 00:00:00 PDT"], "2013-04-27 23:59:59 PDT", "2013-05-11 23:59:59 PDT", true
  end

  def test_zeros_week_mon
    assert_zeros :week, "2013-05-01 20:00:00 UTC", ["2013-04-22 00:00:00 UTC", "2013-04-29 00:00:00 UTC", "2013-05-06 00:00:00 UTC"], "2013-04-27 23:59:59 UTC", "2013-05-11 23:59:59 UTC", false, week_start: :mon
  end

  def test_zeros_week_time_zone_mon
    assert_zeros :week, "2013-05-01 20:00:00 PDT", ["2013-04-22 00:00:00 PDT", "2013-04-29 00:00:00 PDT", "2013-05-06 00:00:00 PDT"], "2013-04-27 23:59:59 PDT", "2013-05-11 23:59:59 PDT", true, week_start: :mon
  end

  def test_zeros_week_sat
    assert_zeros :week, "2013-05-01 20:00:00 UTC", ["2013-04-20 00:00:00 UTC", "2013-04-27 00:00:00 UTC", "2013-05-04 00:00:00 UTC"], "2013-04-26 23:59:59 UTC", "2013-05-10 23:59:59 UTC", false, week_start: :sat
  end

  def test_zeros_week_time_zone_sat
    assert_zeros :week, "2013-05-01 20:00:00 PDT", ["2013-04-20 00:00:00 PDT", "2013-04-27 00:00:00 PDT", "2013-05-04 00:00:00 PDT"], "2013-04-26 23:59:59 PDT", "2013-05-10 23:59:59 PDT", true, week_start: :sat
  end

  def test_zeros_month
    assert_zeros :month, "2013-04-16 20:00:00 UTC", ["2013-03-01 00:00:00 UTC", "2013-04-01 00:00:00 UTC", "2013-05-01 00:00:00 UTC"], "2013-03-01 00:00:00 UTC", "2013-05-31 23:59:59 UTC"
  end

  def test_zeros_month_time_zone
    assert_zeros :month, "2013-04-16 20:00:00 PDT", ["2013-03-01 00:00:00 PST", "2013-04-01 00:00:00 PDT", "2013-05-01 00:00:00 PDT"], "2013-03-01 00:00:00 PST", "2013-05-31 23:59:59 PDT", true
  end

  def test_zeros_year
    assert_zeros :year, "2013-04-16 20:00:00 UTC", ["2012-01-01 00:00:00 UTC", "2013-01-01 00:00:00 UTC", "2014-01-01 00:00:00 UTC"], "2012-01-01 00:00:00 UTC", "2014-12-31 23:59:59 UTC"
  end

  def test_zeros_year_time_zone
    assert_zeros :year, "2013-04-16 20:00:00 PDT", ["2012-01-01 00:00:00 PST", "2013-01-01 00:00:00 PST", "2014-01-01 00:00:00 PST"], "2012-01-01 00:00:00 PST", "2014-12-31 23:59:59 PST", true
  end

  def test_zeros_day_of_week
    create_user "2013-05-01 00:00:00 UTC"
    expected = {}
    7.times do |n|
      expected[n] = n == 3 ? 1 : 0
    end
    assert_equal expected, User.group_by_day_of_week(:created_at, range: true).count
  end

  def test_zeros_hour_of_day
    create_user "2013-05-01 20:00:00 UTC"
    expected = {}
    24.times do |n|
      expected[n] = n == 20 ? 1 : 0
    end
    assert_equal expected, User.group_by_hour_of_day(:created_at, range: true).count
  end

  def test_zeros_excludes_end
    create_user "2013-05-02 00:00:00 UTC"
    expected = {
      utc.parse("2013-05-01 00:00:00 UTC") => 0
    }
    assert_equal expected, User.group_by_day(:created_at, range: Time.parse("2013-05-01 00:00:00 UTC")...Time.parse("2013-05-02 00:00:00 UTC")).count
  end

  def test_zeros_previous_scope
    create_user "2013-05-01 00:00:00 UTC"
    expected = {
      utc.parse("2013-05-01 00:00:00 UTC") => 0
    }
    assert_equal expected, User.where("id = 0").group_by_day(:created_at, range: Time.parse("2013-05-01 00:00:00 UTC")..Time.parse("2013-05-01 23:59:59 UTC")).count
  end

  def test_zeros_datetime
    create_user "2013-05-01 00:00:00 UTC"
    expected = {
      utc.parse("2013-05-01 00:00:00 UTC") => 1
    }
    assert_equal expected, User.group_by_day(:created_at, range: DateTime.parse("2013-05-01 00:00:00 UTC")..DateTime.parse("2013-05-01 00:00:00 UTC")).count
  end

  def test_zeros_null_value
    user = User.create!(name: "Andrew")
    user.update_column :created_at, nil
    assert_equal 0, User.group_by_hour_of_day(:created_at, range: true).count[0]
  end

  def test_zeroes_range_true
    create_user "2013-05-01 00:00:00 UTC"
    create_user "2013-05-03 00:00:00 UTC"
    expected = {
      utc.parse("2013-05-01 00:00:00 UTC") => 1,
      utc.parse("2013-05-02 00:00:00 UTC") => 0,
      utc.parse("2013-05-03 00:00:00 UTC") => 1
    }
    assert_equal expected, User.group_by_day(:created_at, range: true).count
  end

  # week_start

  def test_week_start
    Groupdate.week_start = :mon
    assert_result_time :week, "2013-03-18 00:00:00 UTC", "2013-03-24 23:59:59"
  end

  def test_week_start_and_start_option
    Groupdate.week_start = :mon
    assert_result_time :week, "2013-03-16 00:00:00 UTC", "2013-03-22 23:59:59", false, week_start: :sat
  end

  # misc

  def test_order_hour_of_day
    assert_equal 23, User.group_by_hour_of_day(:created_at).order("hour_of_day desc").count.keys.first
  end

  def test_order_hour_of_day_case
    assert_equal 23, User.group_by_hour_of_day(:created_at).order("hour_of_day DESC").count.keys.first
  end

  def test_order_hour_of_day_reverse
    assert_equal 23, User.group_by_hour_of_day(:created_at).reverse_order.count.keys.first
  end

  def test_order_hour_of_day_order_reverse
    assert_equal 0, User.group_by_hour_of_day(:created_at).order("hour_of_day desc").reverse_order.count.keys.first
  end

  def test_table_name
    assert_empty User.group_by_day("users.created_at").count
  end

  def test_previous_scopes
    create_user "2013-05-01 00:00:00 UTC"
    assert_empty User.where("id = 0").group_by_day(:created_at).count
  end

  def test_time_zone
    create_user "2013-05-01 00:00:00 UTC"
    time_zone = "Pacific Time (US & Canada)"
    assert_equal time_zone, User.group_by_day(:created_at, time_zone: time_zone).count.keys.first.time_zone.name
  end

  def test_where_after
    create_user "2013-05-01 00:00:00 UTC"
    create_user "2013-05-02 00:00:00 UTC"
    expected = {utc.parse("2013-05-02 00:00:00 UTC") => 1}
    assert_equal expected, User.group_by_day(:created_at).where("created_at > ?", "2013-05-01 00:00:00 UTC").count
  end

  def test_group_before
    create_user "2013-05-01 00:00:00 UTC", 1
    create_user "2013-05-02 00:00:00 UTC", 2
    create_user "2013-05-03 00:00:00 UTC", 2
    expected = {
      [1, utc.parse("2013-05-01 00:00:00 UTC")] => 1,
      [1, utc.parse("2013-05-02 00:00:00 UTC")] => 0,
      [1, utc.parse("2013-05-03 00:00:00 UTC")] => 0,
      [2, utc.parse("2013-05-01 00:00:00 UTC")] => 0,
      [2, utc.parse("2013-05-02 00:00:00 UTC")] => 1,
      [2, utc.parse("2013-05-03 00:00:00 UTC")] => 1
    }
    assert_equal expected, User.group(:score).group_by_day(:created_at).order(:score).count
  end

  def test_group_after
    create_user "2013-05-01 00:00:00 UTC", 1
    create_user "2013-05-02 00:00:00 UTC", 2
    create_user "2013-05-03 00:00:00 UTC", 2
    expected = {
      [utc.parse("2013-05-01 00:00:00 UTC"), 1] => 1,
      [utc.parse("2013-05-02 00:00:00 UTC"), 1] => 0,
      [utc.parse("2013-05-03 00:00:00 UTC"), 1] => 0,
      [utc.parse("2013-05-01 00:00:00 UTC"), 2] => 0,
      [utc.parse("2013-05-02 00:00:00 UTC"), 2] => 1,
      [utc.parse("2013-05-03 00:00:00 UTC"), 2] => 1
    }
    assert_equal expected, User.group_by_day(:created_at).group(:score).order(:score).count
  end

  def test_groupdate_multiple
    create_user "2013-05-01 00:00:00 UTC", 1
    expected = {
      [utc.parse("2013-05-01 00:00:00 UTC"), utc.parse("2013-01-01 00:00:00 UTC")] => 1
    }
    assert_equal expected, User.group_by_day(:created_at).group_by_year(:created_at).count
  end

  def test_not_modified
    create_user "2013-05-01 00:00:00 UTC"
    expected = {utc.parse("2013-05-01 00:00:00 UTC") => 1}
    relation = User.group_by_day(:created_at)
    relation.where("created_at > ?", "2013-05-01 00:00:00 UTC")
    assert_equal expected, relation.count
  end

  def test_bad_method
    assert_raises(NoMethodError) { User.group_by_day(:created_at).no_such_method }
  end

  def test_respond_to_where
    assert User.group_by_day(:created_at).respond_to?(:order)
  end

  def test_respond_to_bad_method
    assert !User.group_by_day(:created_at).respond_to?(:no_such_method)
  end

  def test_last
    create_user "2011-05-01 00:00:00 UTC"
    create_user "2013-05-01 00:00:00 UTC"
    expected = {
      utc.parse("2012-01-01 00:00:00 UTC") => 0,
      utc.parse("2013-01-01 00:00:00 UTC") => 1,
      utc.parse("2014-01-01 00:00:00 UTC") => 0
    }
    assert_equal expected, User.group_by_year(:created_at, last: 3).count
  end

  def test_format_day
    create_user "2014-03-01 00:00:00 UTC"
    assert_format :day, "March 1, 2014", "%B %-e, %Y"
  end

  def test_format_month
    create_user "2014-03-01 00:00:00 UTC"
    assert_format :month, "March 2014", "%B %Y"
  end

  def test_format_year
    create_user "2014-03-01 00:00:00 UTC"
    assert_format :year, "2014", "%Y"
  end

  def test_format_hour_of_day
    create_user "2014-03-01 00:00:00 UTC"
    assert_format :hour_of_day, "12 am", "%-l %P"
  end

  def test_format_hour_of_day_day_start
    create_user "2014-03-01 00:00:00 UTC"
    assert_format :hour_of_day, "2 am", "%-l %P", day_start: 2
  end

  def test_format_day_of_week
    create_user "2014-03-01 00:00:00 UTC"
    assert_format :day_of_week, "Sun", "%a"
  end

  def test_format_day_of_week_week_start
    create_user "2014-03-01 00:00:00 UTC"
    assert_format :day_of_week, "Sun", "%a", week_start: :sat
  end

  def test_format_multiple_groups
    create_user "2014-03-01 00:00:00 UTC"
    assert_equal ({["Sun", 1] => 1}), User.group_by_week(:created_at, format: "%a").group(:score).count
    assert_equal ({[1, "Sun"] => 1}), User.group(:score).group_by_week(:created_at, format: "%a").count
  end

  # helpers

  def assert_format(method, expected, format, options = {})
    assert_equal expected, User.send(:"group_by_#{method}", :created_at, options.merge(format: format)).count.keys.first
  end

  def assert_result_time(method, expected, time_str, time_zone = false, options = {})
    expected = {utc.parse(expected).in_time_zone(time_zone ? "Pacific Time (US & Canada)" : utc) => 1}
    assert_equal expected, result(method, time_str, time_zone, options)
  end

  def assert_result(method, expected, time_str, time_zone = false, options = {})
    assert_equal 1, result(method, time_str, time_zone, options)[expected]
  end

  def result(method, time_str, time_zone = false, options = {})
    create_user time_str
    User.send(:"group_by_#{method}", :created_at, options.merge(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil)).count
  end

  def assert_zeros(method, created_at, keys, range_start, range_end, time_zone = nil, options = {})
    create_user created_at
    expected = {}
    keys.each_with_index do |key, i|
      expected[utc.parse(key).in_time_zone(time_zone ? "Pacific Time (US & Canada)" : utc)] = i == 1 ? 1 : 0
    end
    assert_equal expected, User.send(:"group_by_#{method}", :created_at, options.merge(time_zone: time_zone ? "Pacific Time (US & Canada)" : nil, range: Time.parse(range_start)..Time.parse(range_end))).count
  end

  def create_user(created_at, score = 1)
    User.create! :name => "Andrew", :score => score, :created_at => utc.parse(created_at)
  end

  def utc
    ActiveSupport::TimeZone["UTC"]
  end

  def teardown
    User.delete_all
  end

end
