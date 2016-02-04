require_relative "test_helper"

class TestPostgresql < Minitest::Test
  include TestGroupdate

  def setup
    super
    User.establish_connection adapter: "postgresql", database: "groupdate_test"
  end

  def test_no_column
    assert_raises(ArgumentError) { User.group_by_day.first }
  end
end
