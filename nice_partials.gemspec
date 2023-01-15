# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/nice_partials/version"

Gem::Specification.new do |gem|
  gem.name          = "nice_partials"
  gem.version       = NicePartials::VERSION
  gem.summary       = "A little bit of magic to make partials perfect for components."
  gem.description   = "A little bit of magic to make partials perfect for components."
  gem.authors       = ["Andrew Culver", "Dom Christie"]
  gem.email         = ["andrew.culver@gmail.com", "christiedom@gmail.com"]
  gem.homepage      = "https://github.com/bullet-train-co/nice_partials"
  gem.license       = "MIT"

    # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gem.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  gem.bindir = "exe"
  gem.executables = gem.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.0"

  gem.add_dependency "actionview", '>= 4.2.6'

  gem.add_development_dependency "rails"
  gem.add_development_dependency "standard"
end
