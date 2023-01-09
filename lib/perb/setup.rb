# frozen_string_literal: true

require_relative "../perb"

ENV["PERF_BUILDID_DIR"] = "1"

class << RubyVM::InstructionSequence
  prepend(Perb::InstructionSequenceExt)
end
