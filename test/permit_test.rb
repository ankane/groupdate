require_relative "test_helper"

class PermitTest < Minitest::Test
  def test_permit
    error = assert_raises(ArgumentError) { User.group_by_period(:day, :created_at, permit: %w(week)).count }
    assert_equal "Unpermitted period", error.message
  end

  def test_permit_bad_period
    error = assert_raises(ArgumentError) { User.group_by_period(:bad_period, :created_at).count }
    assert_equal "Unpermitted period", error.message
  end

  def test_permit_symbol_symbols
    assert_equal ({}), User.group_by_period(:day, :created_at, permit: [:day]).count
  end

  def test_permit_string_symbols
    assert_equal ({}), User.group_by_period("day", :created_at, permit: [:day]).count
  end

  def test_permit_symbol_strings
    assert_equal ({}), User.group_by_period(:day, :created_at, permit: %w(day)).count
  end

  def test_permit_string_strings
    assert_equal ({}), User.group_by_period("day", :created_at, permit: %w(day)).count
  end
end
