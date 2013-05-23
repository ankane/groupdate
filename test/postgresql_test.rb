require "test_helper"

class TestPostgresql < Minitest::Test
  include TestGroupdate

  def setup
    User.establish_connection :adapter => "postgresql", :database => "groupdate_test"
  end

  def time_key(key)
    if RUBY_PLATFORM == "java"
      key.utc.strftime("%Y-%m-%d %H:%M:%S%z")[0..-3]
    else
      if ActiveRecord::VERSION::MAJOR == 3
        key.utc.strftime("%Y-%m-%d %H:%M:%S+00")
      else
        key
      end
    end
  end

  def number_key(key)
    if RUBY_PLATFORM != "java" and ActiveRecord::VERSION::MAJOR == 3
      key.to_s
    else
      key
    end
  end

end
