require "minitest/autorun"
require "active_record"
require "groupdate"
require "logger"

# for debugging
# ActiveRecord::Base.logger = Logger.new(STDOUT)

# rails does this in activerecord/lib/active_record/railtie.rb
ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true

# start connection
ActiveRecord::Base.establish_connection adapter: "postgresql", database: "groupdate"

# ActiveRecord::Migration.create_table :users do |t|
#   t.string :name
#   t.integer :score
#   t.timestamps
# end

class User < ActiveRecord::Base
end

class TestGroupdate < MiniTest::Unit::TestCase
  def setup
    User.delete_all
    [
      {name: "Andrew", score: 1, created_at: Time.parse("2013-04-01 00:00:00 UTC")},
      {name: "Jordan", score: 2, created_at: Time.parse("2013-04-01 00:00:00 UTC")},
      {name: "Nick",   score: 3, created_at: Time.parse("2013-04-02 00:00:00 UTC")}
    ].each{|u| User.create!(u) }
  end

  def test_count
    expected = {
      "2013-04-01 00:00:00+00" => 2,
      "2013-04-02 00:00:00+00" => 1
    }
    assert_equal expected, User.group_by_day(:created_at).count
  end

  def test_time_zone
    expected = {
      "2013-03-31 07:00:00+00" => 2,
      "2013-04-01 07:00:00+00" => 1
    }
    assert_equal expected, User.group_by_day(:created_at, "America/Los_Angeles").count
  end

  def test_where
    assert_equal({"2013-04-02 00:00:00+00" => 1}, User.where("score > 2").group_by_day(:created_at).count)
  end
end
