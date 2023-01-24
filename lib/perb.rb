# frozen_string_literal: true

require_relative "perb/version"
require_relative "perb/perb"
require "syntax_tree"

ENV["PERF_BUILDID_DIR"] = "1"

module Perb
  # Extension module for RubyVM::InstructionSequence which patches
  # the load_iseq method to use the Perb rewriter.
  module InstructionSequenceExt
    def load_iseq(path)
      visitor = SyntaxTree.mutation do |visitor|
        visitor.mutate("DefNode") do |node|
          method_name = node.name.value || "*unknown*"
          method_info = "#{method_name} @ #{path}:#{node.location.start_line}:#{node.location.start_column}"

          wrapper_id = Perb.build_wrapper(method_info)
          new_body = [SyntaxTree::MethodAddBlock.new(
            call: SyntaxTree::CallNode.new(
              receiver: SyntaxTree::VarRef.new(
                value: SyntaxTree::Const.new(
                  value: "Perb",
                  location: node.bodystmt.location
                ),
                location: node.bodystmt.location
              ),
              operator: :"::",
              location: node.bodystmt.location,
              message: SyntaxTree::Ident.new(value: "wrapper", location: node.bodystmt.location),
              arguments: SyntaxTree::ArgParen.new(
                arguments: SyntaxTree::Args.new(
                  parts: [SyntaxTree::Const.new(value: wrapper_id, location: node.bodystmt.location)],
                  location: node.bodystmt.location
                ),
                location: node.bodystmt.location
              )
            ),
            block: SyntaxTree::BlockNode.new(
              opening: SyntaxTree::Kw.new(value: "do", location: node.bodystmt.location),
              block_var: nil,
              bodystmt: node.bodystmt,
              location: node.bodystmt.location
            ),
            location: node.bodystmt.location,
          )]
          new_statements = node.bodystmt.statements.copy(body: new_body)
          new_bodystmt = node.bodystmt.copy(statements: new_statements)
          new_node = node.copy(bodystmt: new_bodystmt)

          new_node
        end
      end
      source = SyntaxTree.read(path)
      program = SyntaxTree.parse(source)
      RubyVM::InstructionSequence.compile(SyntaxTree::Formatter.format(source, program.accept(visitor)), path, path)
    end
  end
end
