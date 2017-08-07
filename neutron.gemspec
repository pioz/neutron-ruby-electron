# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'neutron/version'

Gem::Specification.new do |spec|
  spec.name          = "neutron-ruby-electron"
  spec.version       = Neutron::VERSION
  spec.authors       = ["pioz"]
  spec.email         = ["epilotto@gmx.com"]

  spec.summary       = %q{Mini framework to build desktop app with Electron and Ruby}
  spec.description   = %q{Mini framework to build desktop app with Electron and Ruby}
  spec.homepage      = "https://github.com/pioz/neutron-ruby-electron"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org/"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = ["neutron"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency "thor", "~> 0.19"
  spec.add_runtime_dependency "sys-proctable", "~> 1.1"
end
