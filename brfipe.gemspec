#encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require "brfipe/version"

Gem::Specification.new do |s|
  s.name        = "brfipe"
  s.version     = Brfipe::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Rodrigo Batista da Silva"]
  s.email       = ["rbsilva.ti@gmail.com"]
  s.homepage    = "https://github.com/rbsilva/brfipe"
  s.summary     = "Gem para consultas no site da fipe."
  s.description = "brfipe é uma gem que tem como objetivo realizar consultas no site da fipe (fundação instituto de pesquisas econômicas) na seção de \"Preço Médio de Veículos\"."

  s.rubyforge_project = "brfipe"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")

  s.add_development_dependency "rspec"
end
