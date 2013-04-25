require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "logger"

# for debugging
# ActiveRecord::Base.logger = Logger.new(STDOUT)

# rails does this in activerecord/lib/active_record/railtie.rb
ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true

class User < ActiveRecord::Base
end

# migrations
%w(postgresql mysql2).each do |adapter|
  ActiveRecord::Base.establish_connection adapter: adapter, database: "groupdate_test", username: adapter == "mysql2" ? "root" : nil

  unless ActiveRecord::Base.connection.table_exists? "users"
    ActiveRecord::Migration.create_table :users do |t|
      t.string :name
      t.integer :score
      t.timestamps
    end
  end
end

describe Groupdate do
  %w(postgresql mysql2).each do |adapter|
    describe adapter do

      before do
        User.establish_connection adapter: adapter, database: "groupdate_test", username: adapter == "mysql2" ? "root" : nil
        User.delete_all
      end

      it "works!" do
        [
          {name: "Andrew", score: 1, created_at: Time.parse("2013-04-01 00:00:00 UTC")},
          {name: "Jordan", score: 2, created_at: Time.parse("2013-04-01 00:00:00 UTC")},
          {name: "Nick",   score: 3, created_at: Time.parse("2013-04-02 00:00:00 UTC")}
        ].each{|u| User.create!(u) }

        assert_equal(
          {
            time_key("2013-04-01 00:00:00 UTC") => 1,
            time_key("2013-04-02 00:00:00 UTC") => 1
          },
          User.where("score > 1").group_by_day(:created_at).count
        )
      end

      it "doesn't throw exception with order" do
        User.group_by_day(:created_at).order("group_field desc").limit(20).count == {}
      end

      it "group_by_second" do
        assert_group :second, "2013-04-01 00:00:01 UTC", "2013-04-01 00:00:01 UTC"
      end

      it "group_by_minute" do
        assert_group :minute, "2013-04-01 00:01:01 UTC", "2013-04-01 00:01:00 UTC"
      end

      it "group_by_hour" do
        assert_group :hour, "2013-04-01 01:01:01 UTC", "2013-04-01 01:00:00 UTC"
      end

      it "group_by_day" do
        assert_group :day, "2013-04-01 01:01:01 UTC", "2013-04-01 00:00:00 UTC"
      end

      it "group_by_day with time zone" do
        assert_group_tz :day, "2013-04-01 01:01:01 UTC", "2013-03-31 07:00:00 UTC"
      end

      it "group_by_week" do
        assert_group :week, "2013-03-17 01:01:01 UTC", "2013-03-17 00:00:00 UTC"
      end

      it "group_by_week with time zone" do # day of DST
        assert_group_tz :week, "2013-03-17 01:01:01 UTC", "2013-03-10 08:00:00 UTC"
      end

      it "group_by_month" do
        assert_group :month, "2013-04-01 01:01:01 UTC", "2013-04-01 00:00:00 UTC"
      end

      it "group_by_month with time zone" do
        assert_group_tz :month, "2013-04-01 01:01:01 UTC", "2013-03-01 08:00:00 UTC"
      end

      it "group_by_year" do
        assert_group :year, "2013-01-01 01:01:01 UTC", "2013-01-01 00:00:00 UTC"
      end

      it "group_by_year with time zone" do
        assert_group_tz :year, "2013-01-01 01:01:01 UTC", "2012-01-01 08:00:00 UTC"
      end

      it "group_by_hour_of_day" do
        assert_group_number :hour_of_day, "2013-01-01 11:00:00 UTC", 11
      end

      it "group_by_hour_of_day with time zone" do
        assert_group_number_tz :hour_of_day, "2013-01-01 11:00:00 UTC", 3
      end

      it "group_by_day_of_week" do
        assert_group_number :day_of_week, "2013-03-03 00:00:00 UTC", 0
      end

      it "group_by_day_of_week with time zone" do
        assert_group_number_tz :day_of_week, "2013-03-03 00:00:00 UTC", 6
      end
    end
  end

  # helper methods

  def assert_group(method, created_at, key, time_zone = nil)
    create_user created_at
    assert_equal({time_key(key) => 1}, User.send(:"group_by_#{method}", :created_at, time_zone).count)
  end

  def assert_group_tz(method, created_at, key)
    assert_group method, created_at, key, "Pacific Time (US & Canada)"
  end

  def assert_group_number(method, created_at, key, time_zone = nil)
    create_user created_at
    assert_equal({number_key(key) => 1}, User.send(:"group_by_#{method}", :created_at, time_zone).count)
  end

  def assert_group_number_tz(method, created_at, key)
    assert_group_number method, created_at, key, "Pacific Time (US & Canada)"
  end

  def time_key(key)
    User.connection.adapter_name == "PostgreSQL" && ActiveRecord::VERSION::MAJOR == 3 ? Time.parse(key).strftime("%Y-%m-%d %H:%M:%S+00") : Time.parse(key)
  end

  def number_key(key)
    User.connection.adapter_name == "PostgreSQL" ? (ActiveRecord::VERSION::MAJOR == 3 ? key.to_s : key.to_f) : key
  end

  def create_user(created_at)
    User.create!(name: "Andrew", score: 1, created_at: Time.parse(created_at))
  end

end
