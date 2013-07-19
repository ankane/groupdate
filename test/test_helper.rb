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

  @@default_config = Hash[Groupdate.class_variables.collect { |opt| [opt[2..-1].to_sym, Groupdate.class_variable_get(opt)] }]

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
    assert_result_time :week, "2013-03-18 00:00:00 UTC", "2013-03-24 23:59:59", false, :start => :mon
  end

  def test_week_start_of_week_mon
    assert_result_time :week, "2013-03-25 00:00:00 UTC", "2013-03-25 00:00:00", false, :start => :mon
  end

  def test_week_end_of_week_with_time_zone_mon
    assert_result_time :week, "2013-03-11 00:00:00 PDT", "2013-03-18 06:59:59", true, :start => :mon
  end

  def test_week_start_of_week_with_time_zone_mon
    assert_result_time :week, "2013-03-18 00:00:00 PDT", "2013-03-18 07:00:00", true, :start => :mon
  end

  # week starting on saturday

  def test_week_end_of_week_sat
    assert_result_time :week, "2013-03-16 00:00:00 UTC", "2013-03-22 23:59:59", false, :start => :sat
  end

  def test_week_start_of_week_sat
    assert_result_time :week, "2013-03-23 00:00:00 UTC", "2013-03-23 00:00:00", false, :start => :sat
  end

  def test_week_end_of_week_with_time_zone_sat
    assert_result_time :week, "2013-03-09 00:00:00 PST", "2013-03-16 06:59:59", true, :start => :sat
  end

  def test_week_start_of_week_with_time_zone_sat
    assert_result_time :week, "2013-03-16 00:00:00 PDT", "2013-03-16 07:00:00", true, :start => :sat
  end

  # config week starting key

  def test_week_start_of_week_mon_from_config
    with_config :week_start => :mon do
      assert_result_time :week, "2013-03-25 00:00:00 UTC", "2013-03-25 00:00:00", false
    end
  end

  def test_week_end_of_week_mon_from_config
    with_config :week_start => :mon do
      assert_result_time :week, "2013-03-18 00:00:00 UTC", "2013-03-24 23:59:59", false
    end
  end

  def test_week_end_of_week_with_time_zone_mon_from_config
    with_config :week_start => :mon do
      assert_result_time :week, "2013-03-11 00:00:00 PDT", "2013-03-18 06:59:59", true
    end
  end

  def test_week_start_of_week_with_time_zone_mon_from_config
    with_config :week_start => :mon do
      assert_result_time :week, "2013-03-18 00:00:00 PDT", "2013-03-18 07:00:00", true
    end
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
    assert_zeros :week, "2013-05-01 20:00:00 UTC", ["2013-04-22 00:00:00 UTC", "2013-04-29 00:00:00 UTC", "2013-05-06 00:00:00 UTC"], "2013-04-27 23:59:59 UTC", "2013-05-11 23:59:59 UTC", false, :start => :mon
  end

  def test_zeros_week_time_zone_mon
    assert_zeros :week, "2013-05-01 20:00:00 PDT", ["2013-04-22 00:00:00 PDT", "2013-04-29 00:00:00 PDT", "2013-05-06 00:00:00 PDT"], "2013-04-27 23:59:59 PDT", "2013-05-11 23:59:59 PDT", true, :start => :mon
  end

  def test_zeros_week_sat
    assert_zeros :week, "2013-05-01 20:00:00 UTC", ["2013-04-20 00:00:00 UTC", "2013-04-27 00:00:00 UTC", "2013-05-04 00:00:00 UTC"], "2013-04-26 23:59:59 UTC", "2013-05-10 23:59:59 UTC", false, :start => :sat
  end

  def test_zeros_week_time_zone_sat
    assert_zeros :week, "2013-05-01 20:00:00 PDT", ["2013-04-20 00:00:00 PDT", "2013-04-27 00:00:00 PDT", "2013-05-04 00:00:00 PDT"], "2013-04-26 23:59:59 PDT", "2013-05-10 23:59:59 PDT", true, :start => :sat
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
    assert_equal expected, User.group_by_day_of_week(:created_at, Time.zone, true).count(:created_at)
  end

  def test_zeros_hour_of_day
    create_user "2013-05-01 20:00:00 UTC"
    expected = {}
    24.times do |n|
      expected[n] = n == 20 ? 1 : 0
    end
    assert_equal expected, User.group_by_hour_of_day(:created_at, Time.zone, true).count(:created_at)
  end

  def test_zeros_excludes_end
    create_user "2013-05-02 00:00:00 UTC"
    expected = {
      Time.parse("2013-05-01 00:00:00 UTC") => 0
    }
    assert_equal expected, User.group_by_day(:created_at, Time.zone, Time.parse("2013-05-01 00:00:00 UTC")...Time.parse("2013-05-02 00:00:00 UTC")).count
  end

  def test_zeros_previous_scope
    create_user "2013-05-01 00:00:00 UTC"
    expected = {
      Time.parse("2013-05-01 00:00:00 UTC") => 0
    }
    assert_equal expected, User.where("id = 0").group_by_day(:created_at, Time.zone, Time.parse("2013-05-01 00:00:00 UTC")..Time.parse("2013-05-01 23:59:59 UTC")).count
  end

  def test_zeros_datetime
    create_user "2013-05-01 00:00:00 UTC"
    expected = {
      Time.parse("2013-05-01 00:00:00 UTC") => 1
    }
    assert_equal expected, User.group_by_day(:created_at, Time.zone, DateTime.parse("2013-05-01 00:00:00 UTC")..DateTime.parse("2013-05-01 00:00:00 UTC")).count
  end

  def test_zeros_null_value
    user = User.create!(name: "Andrew")
    user.update_column :created_at, nil
    assert_equal 0, User.group_by_hour_of_day(:created_at, Time.zone, true).count[0]
  end

  # misc

  def test_order_day
    assert_empty User.group_by_day(:created_at).order("day desc").limit(20).count
  end

  def test_order_week
    assert_empty User.group_by_week(:created_at).order("week asc").count
  end

  def test_order_hour_of_day
    assert_empty User.group_by_hour_of_day(:created_at).order("hour_of_day desc").count
  end

  def test_table_name
    assert_empty User.group_by_day("users.created_at").count
  end

  def test_previous_scopes
    create_user "2013-05-01 00:00:00 UTC"
    assert_empty User.where("id = 0").group_by_day(:created_at).count
  end

  # helpers

  def assert_result_time(method, expected, time_str, time_zone = false, options = {})
    assert_result method, Time.parse(expected), time_str, time_zone, options
  end

  def assert_result(method, expected, time_str, time_zone = false, options = {})
    create_user time_str
    expected = expected.is_a?(Time) ? time_key(expected) : number_key(expected)
    assert_equal ordered_hash({expected => 1}), User.send(:"group_by_#{method}", :created_at, time_zone ? "Pacific Time (US & Canada)" : nil, options).order(method.to_s).count
  end

  def assert_zeros(method, created_at, keys, range_start, range_end, time_zone = nil, options = {})
    create_user created_at
    expected = {}
    keys.each_with_index do |key, i|
      expected[Time.parse(key)] = i == 1 ? 1 : 0
    end
    assert_equal expected, User.send(:"group_by_#{method}", :created_at, time_zone ? "Pacific Time (US & Canada)" : nil, Time.parse(range_start)..Time.parse(range_end), options).count
  end

  def ordered_hash(hash)
    RUBY_VERSION =~ /1\.8/ ? hash.inject(ActiveSupport::OrderedHash.new){|h, (k, v)| h[k] = v; h } : hash
  end

  def create_user(created_at)
    User.create! :name => "Andrew", :score => 1, :created_at => ActiveSupport::TimeZone["UTC"].parse(created_at)
  end

  def teardown
    User.delete_all
  end

  def with_config(config)
    setup_config config
    yield
  ensure
    setup_config @@default_config
  end

private

  def setup_config(config)
    config.each do |option, value|
      Groupdate.send "#{option}=", value
    end
  end

end
