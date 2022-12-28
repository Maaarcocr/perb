# frozen_string_literal: true

require_relative "../perb"

class << RubyVM::InstructionSequence
  prepend(Perb::InstructionSequenceExt)
end
