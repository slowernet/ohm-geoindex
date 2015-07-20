require File.expand_path('../lib/ohm/geoindex', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'ohm-geoindex'
  s.version     = Ohm::Geoindex::VERSION
  s.summary     = %q{Geoindices for Ohm::Model (on Redis 3.2+)}
  s.author      = "Eliot Shepard"
  s.email       = "eshepard@slower.net"
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/slowernet/ohm-geoindex'
  s.license     = 'MIT'

  s.add_dependency "ohm", '>= 2.2.0'
  s.add_development_dependency 'test-unit'
end