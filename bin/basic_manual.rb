#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "perb"

$foo_id = Perb::build_wrapper("foo")
$bar_id = Perb::build_wrapper("bar")
$baz_id = Perb::build_wrapper("baz")

def bar
  Perb::wrapper($bar_id) do
    500.times do
      1 + 2
    end
  end
end

def baz
  Perb::wrapper($baz_id) do
    500.times do
      1 + 2
    end
  end
end

def foo
  Perb::wrapper($foo_id) do
    10_000.times do
      bar
      baz
    end
  end
end

foo
