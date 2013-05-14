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
%w(postgresql mysql2 sqlite3).each do |adapter|
  ActiveRecord::Base.establish_connection :adapter => adapter, :database => "groupdate_test", :username => adapter == "mysql2" ? "root" : nil

  unless ActiveRecord::Base.connection.table_exists? "users"
    ActiveRecord::Migration.create_table :users do |t|
      t.string :name
      t.integer :score
      t.timestamps
    end
  end
end

describe Groupdate do
  %w(postgresql mysql2 sqlite3).each do |adapter|
    supports_tz = adapter != "sqlite3"

    describe adapter do

      before do
        User.establish_connection :adapter => adapter, :database => "groupdate_test", :username => adapter == "mysql2" ? "root" : nil
        User.delete_all
      end

      it "works!" do
        [
          {:name => "Andrew", :score => 1, :created_at => Time.parse("2013-04-01 00:00:00 UTC")},
          {:name => "Jordan", :score => 2, :created_at => Time.parse("2013-04-01 00:00:00 UTC")},
          {:name => "Nick",   :score => 3, :created_at => Time.parse("2013-04-02 00:00:00 UTC")}
        ].each{|u| User.create!(u) }

        assert_equal(
          ordered_hash({
            time_key("2013-04-01 00:00:00 UTC") => 1,
            time_key("2013-04-02 00:00:00 UTC") => 1
          }),
          User.where("score > 1").group_by_day(:created_at).count
        )
      end

      it "doesn't throw exception with order" do
        assert_equal({}, User.group_by_day(:created_at).order("day desc").limit(20).count)
        assert_equal({}, User.group_by_week(:created_at).order("week asc").count)
        assert_equal({}, User.group_by_hour_of_day(:created_at).order("hour_of_day desc").count)
      end

      it "allows for table name" do
        assert_equal({}, User.group_by_day("users.created_at").count)
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
        skip unless supports_tz
        assert_group_tz :day, "2013-04-01 01:01:01 UTC", "2013-03-31 07:00:00 UTC"
      end

      it "group_by_week" do
        assert_group :week, "2013-03-17 01:01:01 UTC", "2013-03-17 00:00:00 UTC"
      end

      it "group_by_week with time zone" do # day of DST
        skip unless supports_tz
        assert_group_tz :week, "2013-03-17 01:01:01 UTC", "2013-03-10 08:00:00 UTC"
      end

      it "group_by_month" do
        assert_group :month, "2013-04-01 01:01:01 UTC", "2013-04-01 00:00:00 UTC"
      end

      it "group_by_month with time zone" do
        skip unless supports_tz
        assert_group_tz :month, "2013-04-01 01:01:01 UTC", "2013-03-01 08:00:00 UTC"
      end

      it "group_by_year" do
        assert_group :year, "2013-01-01 01:01:01 UTC", "2013-01-01 00:00:00 UTC"
      end

      it "group_by_year with time zone" do
        skip unless supports_tz
        assert_group_tz :year, "2013-01-01 01:01:01 UTC", "2012-01-01 08:00:00 UTC"
      end

      it "group_by_hour_of_day" do
        assert_group_number :hour_of_day, "2013-01-01 11:00:00 UTC", 11
      end

      it "group_by_hour_of_day with time zone" do
        skip unless supports_tz
        assert_group_number_tz :hour_of_day, "2013-01-01 11:00:00 UTC", 3
      end

      it "group_by_day_of_week" do
        assert_group_number :day_of_week, "2013-03-03 00:00:00 UTC", 0
      end

      it "group_by_day_of_week with time zone" do
        skip unless supports_tz
        assert_group_number_tz :day_of_week, "2013-03-03 00:00:00 UTC", 6
      end

      it "works with previous scopes" do
        create_user "2013-05-01 00:00:00 UTC"
        assert_equal({}, User.where("id = 0").group_by_day(:created_at).count)
      end

      describe "returns zeros" do

        it "group_by_second" do
          assert_zeros :second, "2013-05-01 00:00:01 UTC", ["2013-05-01 00:00:00 UTC", "2013-05-01 00:00:01 UTC", "2013-05-01 00:00:02 UTC"], "2013-05-01 00:00:00.999 UTC", "2013-05-01 00:00:02 UTC"
        end

        it "group_by_minute" do
          assert_zeros :minute, "2013-05-01 00:01:00 UTC", ["2013-05-01 00:00:00 UTC", "2013-05-01 00:01:00 UTC", "2013-05-01 00:02:00 UTC"], "2013-05-01 00:00:59 UTC", "2013-05-01 00:02:00 UTC"
        end

        it "group_by_hour" do
          assert_zeros :hour, "2013-05-01 04:01:01 UTC", ["2013-05-01 03:00:00 UTC", "2013-05-01 04:00:00 UTC", "2013-05-01 05:00:00 UTC"], "2013-05-01 03:59:59 UTC", "2013-05-01 05:00:00 UTC"
        end

        it "group_by_day" do
          assert_zeros :day, "2013-05-01 20:00:00 UTC", ["2013-04-30 00:00:00 UTC", "2013-05-01 00:00:00 UTC", "2013-05-02 00:00:00 UTC"], "2013-04-30 00:00:00 UTC", "2013-05-02 23:59:59 UTC"
        end

        it "group_by_day with time zone" do
          skip unless supports_tz
          assert_zeros_tz :day, "2013-05-01 20:00:00 PDT", ["2013-04-30 00:00:00 PDT", "2013-05-01 00:00:00 PDT", "2013-05-02 00:00:00 PDT"], "2013-04-30 00:00:00 PDT", "2013-05-02 23:59:59 PDT"
        end

        it "group_by_week" do
          assert_zeros :week, "2013-05-01 20:00:00 UTC", ["2013-04-21 00:00:00 UTC", "2013-04-28 00:00:00 UTC", "2013-05-05 00:00:00 UTC"], "2013-04-27 23:59:59 UTC", "2013-05-11 23:59:59 UTC"
        end

        it "group_by_week with time zone" do
          skip unless supports_tz
          assert_zeros_tz :week, "2013-05-01 20:00:00 PDT", ["2013-04-21 00:00:00 PDT", "2013-04-28 00:00:00 PDT", "2013-05-05 00:00:00 PDT"], "2013-04-27 23:59:59 PDT", "2013-05-11 23:59:59 PDT"
        end

        it "group_by_month" do
          assert_zeros :month, "2013-04-16 20:00:00 UTC", ["2013-03-01 00:00:00 UTC", "2013-04-01 00:00:00 UTC", "2013-05-01 00:00:00 UTC"], "2013-03-01 00:00:00 UTC", "2013-05-31 23:59:59 UTC"
        end

        it "group_by_month with time zone" do
          skip unless supports_tz
          assert_zeros_tz :month, "2013-04-16 20:00:00 PDT", ["2013-03-01 00:00:00 PST", "2013-04-01 00:00:00 PDT", "2013-05-01 00:00:00 PDT"], "2013-03-01 00:00:00 PST", "2013-05-31 23:59:59 PDT"
        end

        it "group_by_year" do
          assert_zeros :year, "2013-04-16 20:00:00 UTC", ["2012-01-01 00:00:00 UTC", "2013-01-01 00:00:00 UTC", "2014-01-01 00:00:00 UTC"], "2012-01-01 00:00:00 UTC", "2014-12-31 23:59:59 UTC"
        end

        it "group_by_year with time zone" do
          skip unless supports_tz
          assert_zeros_tz :year, "2013-04-16 20:00:00 PDT", ["2012-01-01 00:00:00 PST", "2013-01-01 00:00:00 PST", "2014-01-01 00:00:00 PST"], "2012-01-01 00:00:00 PST", "2014-12-31 23:59:59 PST"
        end

        it "group_by_day_of_week" do
          create_user "2013-05-01 00:00:00 UTC"
          expected = {}
          7.times do |n|
            expected[n] = n == 3 ? 1 : 0
          end
          assert_equal(expected, User.group_by_day_of_week(:created_at, Time.zone, true).count(:created_at))
        end

        it "group_by_hour_of_day" do
          create_user "2013-05-01 20:00:00 UTC"
          expected = {}
          24.times do |n|
            expected[n] = n == 20 ? 1 : 0
          end
          assert_equal(expected, User.group_by_hour_of_day(:created_at, Time.zone, true).count(:created_at))
        end

        it "excludes end" do
          create_user "2013-05-02 00:00:00 UTC"
          expected = {
            Time.parse("2013-05-01 00:00:00 UTC") => 0
          }
          assert_equal(expected, User.group_by_day(:created_at, Time.zone, Time.parse("2013-05-01 00:00:00 UTC")...Time.parse("2013-05-02 00:00:00 UTC")).count)
        end

        it "works with previous scopes" do
          create_user "2013-05-01 00:00:00 UTC"
          expected = {
            Time.parse("2013-05-01 00:00:00 UTC") => 0
          }
          assert_equal(expected, User.where("id = 0").group_by_day(:created_at, Time.zone, Time.parse("2013-05-01 00:00:00 UTC")..Time.parse("2013-05-01 23:59:59 UTC")).count)
        end

      end

    end
  end

  # helper methods

  def assert_group(method, created_at, key, time_zone = nil)
    create_user created_at
    assert_equal(ordered_hash({time_key(key) => 1}), User.send(:"group_by_#{method}", :created_at, time_zone).order(method.to_s).count)
  end

  def assert_group_tz(method, created_at, key)
    assert_group method, created_at, key, "Pacific Time (US & Canada)"
  end

  def assert_group_number(method, created_at, key, time_zone = nil)
    create_user created_at
    assert_equal(ordered_hash({number_key(key) => 1}), User.send(:"group_by_#{method}", :created_at, time_zone).order(method.to_s).count)
  end

  def assert_group_number_tz(method, created_at, key)
    assert_group_number method, created_at, key, "Pacific Time (US & Canada)"
  end

  def assert_zeros(method, created_at, keys, range_start, range_end, time_zone = nil, java_hack = false)
    create_user created_at
    expected = {}
    keys.each_with_index do |key, i|
      expected[Time.parse(key)] = i == 1 ? 1 : 0
    end
    assert_equal(expected, User.send(:"group_by_#{method}", :created_at, time_zone, Time.parse(range_start)..Time.parse(range_end)).count)
  end

  def assert_zeros_tz(method, created_at, keys, range_start, range_end)
    assert_zeros method, created_at, keys, range_start, range_end, "Pacific Time (US & Canada)", true
  end

  def time_key(key)
    if RUBY_PLATFORM == "java"
      if User.connection.adapter_name == "PostgreSQL"
        Time.parse(key).utc.strftime("%Y-%m-%d %H:%M:%S%z")[0..-3]
      else
        Time.parse(key).strftime("%Y-%m-%d %H:%M:%S").gsub(/ 00\:00\:00\z/, "")
      end
    else
      if User.connection.adapter_name == "PostgreSQL" && ActiveRecord::VERSION::MAJOR == 3
        Time.parse(key).utc.strftime("%Y-%m-%d %H:%M:%S+00")
      elsif User.connection.adapter_name == "SQLite"
        key
      else
        Time.parse(key)
      end
    end
  end

  def number_key(key)
    if RUBY_PLATFORM == "java"
      if User.connection.adapter_name == "PostgreSQL"
        key.to_f
      else
        key
      end
    else
      if User.connection.adapter_name == "PostgreSQL" || User.connection.adapter_name == "SQLite"
        ActiveRecord::VERSION::MAJOR == 3 ? key.to_s : key.to_f
      else
        key
      end
    end
  end

  def ordered_hash(hash)
    RUBY_VERSION =~ /1\.8/ ? hash.inject(ActiveSupport::OrderedHash.new){|h, (k, v)| h[k] = v; h } : hash
  end

  def create_user(created_at)
    User.create!(:name => "Andrew", :score => 1, :created_at => Time.parse(created_at))
  end

end
