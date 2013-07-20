require "test_helper"

class TestMysql < Minitest::Unit::TestCase
  include TestGroupdate

  def setup
    super
    User.establish_connection :adapter => "mysql2", :database => "groupdate_test", :username => "root"
  end

  def time_key(key)
    key
  end

  def number_key(key)
    key
  end

end
