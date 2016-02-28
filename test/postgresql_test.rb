require_relative "test_helper"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "groupdate_test"
create_tables

class TestPostgresql < Minitest::Test
  include TestGroupdate

  def test_no_column
    assert_raises(ArgumentError) { User.group_by_day.first }
  end
end
