require_relative "test_helper"

class PermitTest < Minitest::Test
  def test_permit
    error = assert_raises(ArgumentError) do
      call_method(:day, :created_at, permit: %w(week))
    end
    assert_equal "Unpermitted period", error.message
  end

  def test_permit_bad_period
    error = assert_raises(ArgumentError) do
      call_method(:bad_period, :created_at)
    end
    assert_equal "Unpermitted period", error.message
  end

  def test_permit_symbol_symbols
    assert_empty call_method(:day, :created_at, permit: [:day])
  end

  def test_permit_string_symbols
    assert_empty call_method("day", :created_at, permit: [:day])
  end

  def test_permit_symbol_strings
    assert_empty call_method(:day, :created_at, permit: %w(day))
  end

  def test_permit_string_strings
    assert_empty call_method("day", :created_at, permit: %w(day))
  end
end
