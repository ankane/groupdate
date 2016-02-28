require_relative "test_helper"

ActiveRecord::Base.establish_connection adapter: "mysql2", database: "groupdate_test", username: "root"
create_tables

class TestMysql < Minitest::Test
  include TestGroupdate
end
