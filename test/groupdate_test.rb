require "minitest/spec"
require "minitest/autorun"
require "active_record"
require "groupdate"
require "logger"

# for debugging
# ActiveRecord::Base.logger = Logger.new(STDOUT)

# rails does this in activerecord/lib/active_record/railtie.rb
ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true

class User < ActiveRecord::Base
end

describe Groupdate do
  %w(postgresql mysql mysql2).each do |adapter|
    describe adapter do
      before do
        ActiveRecord::Base.establish_connection adapter: adapter, database: "groupdate"

        # ActiveRecord::Migration.create_table :users do |t|
        #   t.string :name
        #   t.integer :score
        #   t.timestamps
        # end

        User.delete_all
      end

      it "works!" do
        [
          {name: "Andrew", score: 1, created_at: Time.parse("2013-04-01 00:00:10.200 UTC")},
          {name: "Jordan", score: 2, created_at: Time.parse("2013-04-01 00:00:10.200 UTC")},
          {name: "Nick",   score: 3, created_at: Time.parse("2013-04-02 00:00:20.800 UTC")}
        ].each{|u| User.create!(u) }

        assert_equal(
          {"2013-04-01 00:00:00+00" => 1, "2013-04-02 00:00:00+00" => 1},
          User.where("score > 1").group_by_day(:created_at).count
        )
      end

      it "group_by_second" do
        create_user "2013-04-01 00:00:01 UTC"
        assert_equal({"2013-04-01 00:00:01+00" => 1}, User.group_by_second(:created_at).count)
      end

      it "group_by_minute" do
        create_user "2013-04-01 00:01:01 UTC"
        assert_equal({"2013-04-01 00:01:00+00" => 1}, User.group_by_minute(:created_at).count)
      end

      it "group_by_hour" do
        create_user "2013-04-01 01:01:01 UTC"
        assert_equal({"2013-04-01 01:00:00+00" => 1}, User.group_by_hour(:created_at).count)
      end

      it "group_by_day" do
        create_user "2013-04-01 01:01:01 UTC"
        assert_equal({"2013-04-01 00:00:00+00" => 1}, User.group_by_day(:created_at).count)
      end

      it "group_by_day with time zone" do
        create_user "2013-04-01 01:01:01 UTC"
        assert_equal({"2013-03-31 07:00:00+00" => 1}, User.group_by_day(:created_at, "Pacific Time (US & Canada)").count)
      end

      it "group_by_week" do
        create_user "2013-03-17 01:01:01 UTC"
        assert_equal({"2013-03-17 00:00:00+00" => 1}, User.group_by_week(:created_at).count)
      end

      it "group_by_week with time zone" do # day of DST
        create_user "2013-03-17 01:01:01 UTC"
        assert_equal({"2013-03-10 08:00:00+00" => 1}, User.group_by_week(:created_at, "Pacific Time (US & Canada)").count)
      end

      it "group_by_month" do
        create_user "2013-04-01 01:01:01 UTC"
        assert_equal({"2013-04-01 00:00:00+00" => 1}, User.group_by_month(:created_at).count)
      end

      it "group_by_month with time zone" do
        create_user "2013-04-01 01:01:01 UTC"
        assert_equal({"2013-03-01 08:00:00+00" => 1}, User.group_by_month(:created_at, "Pacific Time (US & Canada)").count)
      end

      it "group_by_year" do
        create_user "2013-01-01 01:01:01 UTC"
        assert_equal({"2013-01-01 00:00:00+00" => 1}, User.group_by_year(:created_at).count)
      end

      it "group_by_year with time zone" do
        create_user "2013-01-01 01:01:01 UTC"
        assert_equal({"2012-01-01 08:00:00+00" => 1}, User.group_by_year(:created_at, "Pacific Time (US & Canada)").count)
      end

      it "group_by_hour_of_day" do
        create_user "2013-01-01 11:00:00 UTC"
        assert_equal({"11" => 1}, User.group_by_hour_of_day(:created_at).count)
      end

      it "group_by_hour_of_day with time zone" do
        create_user "2013-01-01 11:00:00 UTC"
        assert_equal({"3" => 1}, User.group_by_hour_of_day(:created_at, "Pacific Time (US & Canada)").count)
      end

      it "group_by_day_of_week" do
        create_user "2013-03-03 00:00:00 UTC"
        assert_equal({"0" => 1}, User.group_by_day_of_week(:created_at).count)
      end

      it "group_by_day_of_week with time zone" do
        create_user "2013-03-03 00:00:00 UTC"
        assert_equal({"6" => 1}, User.group_by_day_of_week(:created_at, "Pacific Time (US & Canada)").count)
      end

      # helper methods

      def create_user(created_at)
        User.create!(name: "Andrew", score: 1, created_at: Time.parse(created_at))
      end

    end
  end
end
