require_relative "test_helper"

class MysqlTest < Minitest::Test
  include TestGroupdate
  include TestDatabase

  def setup
    super
    @@setup ||= begin
      ActiveRecord::Base.establish_connection adapter: "mysql2", database: "groupdate_test", username: "root"
      create_tables
      true
    end
  end
end
