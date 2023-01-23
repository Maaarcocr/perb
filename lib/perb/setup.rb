# frozen_string_literal: true

require_relative "../perb"

ENV["PERF_BUILDID_DIR"] ||= "1"

class << RubyVM::InstructionSequence
  prepend(Perb::InstructionSequenceExt)
end

class Module
  alias_method :perb_original_define_method, :define_method
  def define_method(symbol, *args, &block)
    perb_symbol = :"perb_#{symbol}"
    perb_original_define_method(perb_symbol, *args, &block)
    perb_original_define_method(symbol) do
      Perb::wrapper(Perb.build_wrapper("#{symbol} @ #{__FILE__}:#{__LINE__}")) do
        send(perb_symbol)
      end
    end
  end
end
