# frozen_string_literal: true

require_relative "lib/perb/version"

Gem::Specification.new do |spec|
  spec.name = "perb"
  spec.version = Perb::VERSION
  spec.authors = ["Marco Concetto Rudilosso", "Giovanni Borgh"]
  spec.email = ["marcoc.r@outlook.com"]

  spec.summary = "perb allows perf to profile ruby"
  spec.description = "perb allows perf to profile ruby"
  spec.homepage = "https://github.com/Maaarcocr/perb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/Maaarcocr/perb/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/perb/extconf.rb"] # Future: ["ext/Cargo.toml"] with rubygems >= 3.3.24

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  # needed until rubygems supports Rust support is out of beta
  spec.add_dependency "parser", "~> 3.1"
  spec.add_dependency "rb_sys", "~> 0.9.39"

  # only needed when developing or packaging your gem
  spec.add_development_dependency "rake-compiler", "~> 1.2.0"

  spec.metadata["rubygems_mfa_required"] = "true"
end
