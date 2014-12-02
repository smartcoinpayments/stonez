Gem::Specification.new do |s|
  s.name        = 'stonez'
  s.version     = '0.0.1'
  s.date        = '2014-12-13'
  s.summary     = "Stone Credit Authentication SDK"
  s.description = "Gem for using the Stone API for credit authorization"
  s.authors     = ["Timothy High"]
  s.email       = 'tech@pagpop.com.br'
  s.files       = Dir['lib/*.rb']
  s.homepage    = "https://github.com/techvitalcred/stonez"

  s.add_dependency "nokogiri"
  #s.add_dependency "activesupport"
  #s.add_dependency "activemodel"

end
