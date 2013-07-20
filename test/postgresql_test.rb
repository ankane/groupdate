require "test_helper"

class TestPostgresql < Minitest::Unit::TestCase
  include TestGroupdate

  def setup
    super
    User.establish_connection :adapter => "postgresql", :database => "groupdate_test"
  end

  def time_key(key)
    if ActiveRecord::VERSION::MAJOR == 3
      key.utc.strftime("%Y-%m-%d %H:%M:%S+00")
    else
      key
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
