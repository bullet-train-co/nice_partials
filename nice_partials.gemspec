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

  gem.files         = Dir["{**/}{.*,*}"].select{ |path| File.file?(path) && path !~ /^pkg/ }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = "~> 2.0"

  gem.add_dependency "actionview", '>= 4.2.6'
end
