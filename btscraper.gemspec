Gem::Specification.new do |s|
  s.name        = 'btscraper'
  s.version     = '0.1.0'
  s.summary     = 'Scrape library for bittorrent trackers'
  s.description = 'btscraper is a simple ruby library that allows to retrieve the state of a torrent from a tracker'
  s.authors     = ['Sherkix']
  s.license     = 'MIT'
  s.homepage    = 'https://github.com/sherkix/btscraper'

  s.add_dependency 'uri'
  s.add_dependency 'binascii'
  s.add_dependency 'timeout'
  s.add_development_dependency 'minitest'
  s.required_ruby_version = '>= 2.7.8'
  s.files = Dir['lib/**/*.rb']
end