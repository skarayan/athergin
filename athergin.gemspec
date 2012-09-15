# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'athergin/version'

Gem::Specification.new do |gem|
  gem.name          = 'athergin'
  gem.version       = Athergin::VERSION
  gem.authors       = ['Sarkis Karayan']
  gem.email         = ['skarayan@gmail.com']
  gem.description   = 'Athergin Web Framework'
  gem.summary       = 'Athergin Web Framework'
  gem.homepage      = 'https://github.com/skarayan/athergin'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'core_extensions'
end
