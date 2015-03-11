require_relative "test_helper"

class TestMysql < Minitest::Test
  include TestGroupdate

  def setup
    super
    User.establish_connection :adapter => "mysql2", :database => "groupdate_test", :username => "root"
  end
end
