# frozen_string_literal: true

require "test_helper"

class TestPerb < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Perb::VERSION
  end

  def test_it_returns_120
    result = ::Perb.wrapper do
      120
    end
    assert_equal(result, 120)
  end

  def test_it_returns_hello_world
    result = ::Perb.wrapper do
      "Hello, World!"
    end
    assert_equal(result, "Hello, World!")
  end

  def test_it_returns_1_dot_20
    result = ::Perb.wrapper do
      1.20
    end
    assert_equal(result, 1.20)
  end

  def test_it_returns_true
    result = ::Perb.wrapper do
      true
    end
    assert_equal(result, true)
  end

  def test_it_returns_array
    result = ::Perb.wrapper do
      [1, 2, 3]
    end
    assert_equal(result, [1, 2, 3])
  end

  def test_it_returns_hash
    result = ::Perb.wrapper do
      { a: 1, b: 2, c: 3 }
    end
    assert_equal(result, { a: 1, b: 2, c: 3 })
  end
end
