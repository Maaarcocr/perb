# frozen_string_literal: true

require_relative "perb/version"
require_relative "perb/perb"
require "parser/current"

module Perb
  # This is a tree rewriter that will insert the wrapper code around
  # every method definition.
  class Rewriter < Parser::TreeRewriter
    def on_def(node)
      line = node.location.line || "line?"
      column = node.location.column || "column?"
      method_name = node.children[0] || "*unknown*"
      file_name = @source_rewriter.source_buffer.name
      method_info = "#{method_name} @ #{file_name}:#{line}:#{column}"

      block = node.children[2]
      return if block.nil?

      insert_before(block.loc.expression, "Perb::wrapper(#{Perb.build_wrapper(method_info)}) do\n")
      insert_after(block.loc.expression, "\nend")
    end
  end
end

module Perb
  # Extension module for RubyVM::InstructionSequence which patches
  # the load_iseq method to use the Perb rewriter.
  module InstructionSequenceExt
    def load_iseq(path)
      source = Parser::Source::Buffer.new(path).read
      parser = Parser::CurrentRuby.new
      rewriter = Perb::Rewriter.new

      ast = parser.parse(source)
      source = rewriter.rewrite(source, ast)
      RubyVM::InstructionSequence.compile(source)
    end
  end
end

module Perb
  class Error < StandardError; end
end
