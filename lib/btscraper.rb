
# Scrape library for bittorrent trackers

module BTScraper
  # @!visibility private
  VERSION = '0.1.1'

  # Base class for exceptions
  class BTScraperError < StandardError
  end

  glob = File.join(File.dirname(__FILE__), 'btscraper/**/*.rb')
  Dir[glob].sort.each {|file| require file }
end