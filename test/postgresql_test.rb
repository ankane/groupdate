require_relative "test_helper"

class TestPostgresql < Minitest::Unit::TestCase
  include TestGroupdate

  def setup
    super
    User.establish_connection :adapter => "postgresql", :database => "groupdate_test"
  end

end
