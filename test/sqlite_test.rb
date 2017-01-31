require_relative "test_helper"

class TestSqlite < Minitest::Test
  include TestGroupdate
  include TestDatabase

  def setup
    super
    @@setup ||= begin
      ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
      create_tables
      true
    end
  end

  def test_where_after
    skip
  end

  def call_method(method, field, options)
    if method == :quarter || options[:time_zone] || options[:day_start] || options[:week_start] || Groupdate.week_start != :sun || (Time.zone && options[:time_zone] != false)
      error = assert_raises(Groupdate::Error) { super }
      assert_includes error.message, "not supported for SQLite"
      skip # after assertions
    else
      super
    end
  end
end
