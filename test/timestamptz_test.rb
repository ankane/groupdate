require_relative "test_helper"

# This test demonstrates the real-world value of timestamptz support with default_timezone = :local
# Use case: Application has timestamptz data (from SQL dumps, migrations, etc.) and needs to query it
# with default_timezone = :local (e.g., for compatibility with legacy code)
class TimestamptzRealWorldTest < Minitest::Test
  def test_timestamptz_with_local_timezone_queries_existing_data
    skip unless postgresql?

    original_timezone = ActiveRecord.default_timezone

    begin
      # Insert data with DIFFERENT timezone offsets using raw SQL
      # This demonstrates that timestamptz truly preserves timezone information
      # Data from different timezones: South Africa (+02), Berlin (+01), UTC (+00)
      ActiveRecord::Base.connection.execute("
        DELETE FROM users;
        INSERT INTO users (deleted_at) VALUES
          ('2024-01-15 23:00:00+02'::timestamptz),  -- South Africa time (21:00 UTC)
          ('2024-01-16 00:30:00+01'::timestamptz),  -- Berlin time (23:30 UTC)
          ('2024-01-16 02:00:00+00'::timestamptz);  -- UTC time (02:00 UTC)
      ")

      # Verify the data was stored correctly by checking UTC values
      users = ActiveRecord::Base.connection.execute("
        SELECT deleted_at, deleted_at AT TIME ZONE 'UTC' as utc_time
        FROM users
        ORDER BY deleted_at
      ").to_a

      # PostgreSQL returns Time objects, convert to comparable format
      assert_equal Time.utc(2024, 1, 15, 21, 0, 0), users[0]["utc_time"]  # South Africa -> UTC
      assert_equal Time.utc(2024, 1, 15, 23, 30, 0), users[1]["utc_time"]  # Berlin -> UTC
      assert_equal Time.utc(2024, 1, 16, 2, 0, 0), users[2]["utc_time"]  # UTC -> UTC

      # Now switch to local timezone (e.g., for application compatibility)
      ActiveRecord.default_timezone = :local

      # Group by day in Berlin timezone - should get 2 days
      result = User.group_by_day(:deleted_at, time_zone: "Europe/Berlin").count

      # 21:00 UTC = Jan 15 22:00 CET (same day)
      # 23:30 UTC = Jan 16 00:30 CET (next day)
      # 02:00 UTC = Jan 16 03:00 CET (same day as previous)
      assert_equal 2, result.size
      dates = result.keys.sort
      assert_equal Date.new(2024, 1, 15), dates[0].to_date
      assert_equal 1, result[dates[0]]  # One record on Jan 15
      assert_equal Date.new(2024, 1, 16), dates[1].to_date
      assert_equal 2, result[dates[1]]  # Two records on Jan 16

      # Group by day in South Africa timezone - should get different grouping
      result_sa = User.group_by_day(:deleted_at, time_zone: "Africa/Johannesburg").count

      # 21:00 UTC = Jan 15 23:00 SAST (same day)
      # 23:30 UTC = Jan 16 01:30 SAST (next day)
      # 02:00 UTC = Jan 16 04:00 SAST (same day as previous)
      assert_equal 2, result_sa.size
      dates_sa = result_sa.keys.sort
      assert_equal Date.new(2024, 1, 15), dates_sa[0].to_date
      assert_equal 1, result_sa[dates_sa[0]]
      assert_equal Date.new(2024, 1, 16), dates_sa[1].to_date
      assert_equal 2, result_sa[dates_sa[1]]
    ensure
      ActiveRecord.default_timezone = original_timezone
      User.delete_all
    end
  end

  def test_regular_datetime_still_requires_utc
    skip unless postgresql?

    original_timezone = ActiveRecord.default_timezone

    begin
      ActiveRecord.default_timezone = :local
      User.create!(created_at: Time.now)

      # Regular datetime columns still require default_timezone = :utc
      error = assert_raises(Groupdate::Error) do
        User.group_by_day(:created_at).count
      end

      assert_match(/default_timezone must be :utc/i, error.message)
    ensure
      ActiveRecord.default_timezone = original_timezone
      User.delete_all
    end
  end
end
