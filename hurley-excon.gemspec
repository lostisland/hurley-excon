# coding: utf-8
lib = "hurley-excon"
lib_file = File.expand_path("../lib/#{lib}.rb", __FILE__)
File.read(lib_file) =~ /\bVERSION\s*=\s*["'](.+?)["']/
version = $1

Gem::Specification.new do |spec|
  spec.add_runtime_dependency "excon", "~> 0.42", ">= 0.42.1"
  spec.add_runtime_dependency "hurley", "~> 0.1", ">= 0.1"
  spec.authors = ["Rick Olson"]
  spec.description = %q{Excon connection for Hurley.}
  spec.email = %w(technoweenie@gmail.com)
  spec.homepage = "https://github.com/lostisland/hurley-excon"
  dev_null    = File.exist?("/dev/null") ? "/dev/null" : "NUL"
  git_files   = `git ls-files -z 2>#{dev_null}`
  spec.files = git_files.split("\0") if $?.success?
  spec.test_files = Dir.glob("test/**/*.rb")
  spec.licenses = ["MIT"]
  spec.name = lib
  spec.require_paths = ["lib"]
  spec.summary = "Excon connection for Hurley."
  spec.version = version
end
