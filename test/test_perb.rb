# frozen_string_literal: true

require "test_helper"

class TestPerb < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Perb::VERSION
  end

  def test_it_does_something_useful
    assert ::Perb.wrapper == "Hello World"
  end
end
