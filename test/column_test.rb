require_relative "test_helper"

class ColumnTest < Minitest::Test
  def test_string
    assert_empty User.group("created_at").count
    assert_empty User.group_by_day("created_at").count
  end

  def test_table_name
    assert_empty User.group("users.created_at").count
    assert_empty User.group_by_day("users.created_at").count
  end

  def test_string_with_join
    assert_empty User.joins(:posts).group("created_at").count
    assert_empty User.joins(:posts).group_by_day("created_at").count
  end

  def test_string_function
    error = assert_raises(ActiveRecord::UnknownAttributeReference) do
      User.joins(:posts).group_by_day(now_function).count
    end
    assert_equal "Query method called with non-attribute argument(s): \"#{now_function}\". Use Arel.sql() for known-safe values.", error.message
  end

  def test_string_function_arel
    assert_empty User.joins(:posts).group_by_day(Arel.sql(now_function)).count
  end

  def test_symbol_with_join
    assert_empty User.joins(:posts).group(:created_at).count
    assert_empty User.joins(:posts).group_by_day(:created_at).count
  end

  def test_symbol_undefined_attribute
    create_user "2018-01-01"

    # for sqlite, double-quoted string literals are accepted
    # https://www.sqlite.org/quirks.html
    if sqlite?
      assert_equal ({"created_at2" => 1}), User.group(:created_at2).count

      error = assert_raises(Groupdate::Error) do
        User.group_by_day(:created_at2).count
      end
      assert_equal "Invalid query - be sure to use a date or time column", error.message
    else
      assert_raises(ActiveRecord::StatementInvalid) do
        User.group(:created_at2).count
      end
      assert_raises(ActiveRecord::StatementInvalid) do
        User.group_by_day(:created_at2).count
      end
    end
  end

  def test_symbol_quoted
    sql = User.group_by_day(:missing).to_sql
    quoted_name = User.connection.quote_column_name("missing")
    refute_equal quoted_name, "missing"
    assert_match quoted_name, sql
    # important: makes sure all instances are quoted
    assert_equal sql.split("missing").size, sql.split(quoted_name).size
  end

  def test_alias_attribute
    assert_empty User.group(:signed_up_at).count
    assert_empty User.group_by_day(:signed_up_at).count
  end

  def test_missing
    error = assert_raises(ArgumentError) do
      User.group_by_day.first
    end
    assert_equal "wrong number of arguments (given 0, expected 1)", error.message
  end

  private

  def now_function
    if sqlite?
      "datetime('now')"
    elsif redshift?
      "GETDATE()"
    else
      "NOW()"
    end
  end
end
