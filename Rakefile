# frozen_string_literal: true

require "rake/testtask"
require "rake/extensiontask"
require "bundler/gem_tasks"
require "rubocop/rake_task"

Rake::ExtensionTask.new("perb") do |c|
  c.lib_dir = "lib/perb"
end

task :dev do
  ENV["RB_SYS_CARGO_PROFILE"] = "dev"
end

Rake::TestTask.new(:test) do |t|
  t.deps << :dev << :compile
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

RuboCop::RakeTask.new

task default: %i[test rubocop]
