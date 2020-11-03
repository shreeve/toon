# encoding: utf-8

Gem::Specification.new do |s|
  s.name        = "toon"
  s.version     = "0.0.3"
  s.author      = "Steve Shreeve"
  s.email       = "steve.shreeve@gmail.com"
  s.summary     = "A Ruby gem that makes it easy to cleanup and format data"
  s.description = "This gem is helpful for ETL or other general data cleaning."
  s.homepage    = "https://github.com/shreeve/toon"
  s.license     = "MIT"
  s.files       = `git ls-files`.split("\n") - %w[.gitignore]
end
