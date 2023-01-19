# frozen_string_literal: true

require_relative "perb/version"
require_relative "perb/perb"
require "parser/current"

ENV["PERF_BUILDID_DIR"] = "1"

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
      insert_after(node.loc.expression, "\nend")
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
      RubyVM::InstructionSequence.compile(source, path, path)
    end
  end
end

module Perb
  def self.profile(iterations = 10, &block)
    classes = {}
    trace = TracePoint.new(:call) do |tp|
      next if tp.method_id.to_s.include?("_perb")

      classes[tp.defined_class] ||= Set.new
      next if classes[tp.defined_class].include?(tp.method_id)

      classes[tp.defined_class].add(tp.method_id)
      tp.defined_class.alias_method(:"#{tp.method_id}_perb", tp.method_id)

      method_info = "#{tp.defined_class}::#{tp.method_id} @ #{tp.path}:#{tp.lineno}"
      wrapper = Perb.build_wrapper(method_info)

      tp.defined_class.define_method(tp.method_id) do |*args, **kwargs, &block|
        Perb::wrapper(wrapper) do
          send(:"#{__method__}_perb", *args, **kwargs, &block)
        end
      end
    end

    trace.enable { iterations.times(&block) }

    for cls in classes.keys
      for method in classes[cls]
        cls.alias_method(method, :"#{method}_perb")
        cls.remove_method(:"#{method}_perb")
      end
    end
  end

  class Error < StandardError; end
end
