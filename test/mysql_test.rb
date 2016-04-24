require_relative "test_helper"

class TestMysql < Minitest::Test
  include TestGroupdate
  include TestDatabase

  def setup
    super
    @@setup ||= begin
      ActiveRecord::Base.establish_connection adapter: "mysql", database: "groupdate_test", username: "root"
      create_tables
      true
    end
  end
end
