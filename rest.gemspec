lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rest/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Travis Reeder"]
  gem.email         = ["treeder@gmail.com"]
  gem.description   = "Rest client wrapper that chooses best installed client."
  gem.summary       = "Rest client wrapper that chooses best installed client."
  gem.homepage      = "https://github.com/iron-io/rest"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rest"
  gem.require_paths = ["lib"]
  gem.version       = Rest::VERSION

  gem.required_rubygems_version = ">= 1.3.6"
  gem.required_ruby_version = Gem::Requirement.new(">= 1.8")
  gem.add_runtime_dependency "net-http-persistent", ">= 2.9.1", "< 3"
  gem.add_runtime_dependency "netrc"

  gem.add_development_dependency "typhoeus", ">= 0.5.4"
  gem.add_development_dependency "test-unit"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "uber_config"
  gem.add_development_dependency "quicky", ">= 0.4.0"
  gem.add_development_dependency "excon"

end

