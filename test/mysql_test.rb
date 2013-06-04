require "test_helper"

class TestMysql < Minitest::Test
  include TestGroupdate

  def setup
    User.establish_connection :adapter => "mysql2", :database => "groupdate_test", :username => "root"
  end

  def time_key(key)
    if RUBY_PLATFORM == "java"
      key.utc.strftime("%Y-%m-%d %H:%M:%S").gsub(/ 00\:00\:00\z/, "")
    else
      key
    end
  end

  def number_key(key)
    key
  end

end
