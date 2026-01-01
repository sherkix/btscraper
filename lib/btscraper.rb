
# Scrape library for bittorrent trackers
# @author sherkix

module BTScraper
  # @!visibility private
  VERSION = '0.1.3'

  # Base class for exceptions
  class BTScraperError < StandardError
  end

  glob = File.join(File.dirname(__FILE__), 'btscraper/**/*.rb')
  Dir[glob].sort.each {|file| require file }
end