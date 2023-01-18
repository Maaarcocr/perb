#!/usr/bin/env ruby
# frozen_string_literal: true

def bar
  1_000.times do
    1 + 2
  end
end

def foo
  10_000.times do
    bar
  end
end

foo
