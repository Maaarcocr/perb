#!/usr/bin/env ruby
# frozen_string_literal: true

class Test
  def bar(x)
    100.times do
      1 + 2 + x
    end
  end

  def foo(x = 1)
    10_000.times do
      bar(x)
    end
  end

  define_method(:baz) do
    10.times do
      foo(2) + foo(3) + foo(4)
    end
  end
end

Test.new.baz
