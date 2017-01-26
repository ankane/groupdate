require_relative "test_helper"

class PostgresqlTest < Minitest::Test
  include TestGroupdate
  include TestDatabase

  def setup
    super
    @@setup ||= begin
      ActiveRecord::Base.establish_connection adapter: "postgresql", database: "groupdate_test"
      create_tables
      true
    end
  end
end
