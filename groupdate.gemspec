require_relative "lib/groupdate/version"

Gem::Specification.new do |spec|
  spec.name          = "groupdate"
  spec.version       = Groupdate::VERSION
  spec.summary       = "The simplest way to group temporal data"
  spec.homepage      = "https://github.com/ankane/groupdate"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "activesupport", ">= 5"
end
