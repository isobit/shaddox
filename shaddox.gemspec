# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shaddox/version'

Gem::Specification.new do |spec|
  spec.name          = "shaddox"
  spec.version       = Shaddox::VERSION
  spec.authors       = ["joshglendenning"]
  spec.email         = ["joshglendenning@gmail.com"]
  spec.summary       = %q{Ruby system provisioner.}
  spec.description   = %q{}
  spec.homepage      = "http://nominaltech.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sourcify", "~> 0.6.0.rc4"
  spec.add_dependency "net-ssh", "~> 2.9"
  spec.add_dependency "highline", "~> 1.6"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
end
