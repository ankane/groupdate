require_relative "test_helper"

class RedshiftTest < Minitest::Test
  include TestGroupdate
  include TestDatabase

  def setup
    super
    @@setup ||= begin
      abort("REDSHIFT_URL environment variable must be set in order to run tests") unless ENV["REDSHIFT_URL"].present?

      ActiveRecord::Base.establish_connection(ENV["REDSHIFT_URL"])

      create_redshift_tables
      true
    end
  end
end
