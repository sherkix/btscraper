require 'bencode'
require 'httparty'
require 'binascii'

module BTScraper
  
  # @author sherkix 
  # @see https://bittorrent.org/beps/bep_0048.html BEP 48
  # This class permits you to scrape an HTTP torrent tracker according to the BEP 48
  class HTTPScrape

    attr_reader :tracker, :info_hash
    # @!attribute [r] tracker
    #  @return [String] returns tracker full url
    #  
    # @!attribute [r] info_hash
    #  @return [Array<String>] returns array of infohashes
    # 
    # Create a new HTTPScrape object 
    # 
    # @param tracker [String] Bittorrent HTTP tracker server
    # @param info_hash [Array<String>, String] Array of infohashes or single infohash
    # 
    # @raise [TypeError] if wrong type of argument is provided
    # 
    # @example Default usage
    #  scrape_object = BTScraper::HTTPScrape.new('https://example.com:443/scrape', ['c22b5f9178342609428d6f51b2c5af4c0bde6a42'], ['aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d'])
    #  scrape_object.scrape
    def initialize(tracker, info_hash)
      unless tracker.instance_of? String
        raise TypeError, "String excpected, got #{tracker.class}"
      end
      unless info_hash.instance_of? String or info_hash.instance_of? Array
        raise TypeError, "String or Array excpected, got #{info_hash.class}"
      end

      if info_hash.instance_of? String
        info_hash.downcase!
        BTScraper.check_info_hash Array(info_hash)
      else
        info_hash.map(&:downcase!)
        BTScraper.check_info_hash info_hash
      end
      @tracker = tracker
      @info_hash = Array(info_hash)
    end
    # @example Response example
    #  {"files" => {"xxxxxxxxxxxxxxxxxxxxxxxxxx" => {"complete" => 8, "downloaded" => 9, "incomplete" => 4}, "yyyyyyyyyyyyyyyyyyyyyyyyyy" => {"complete" => 81, "downloaded" => 204, "incomplete" => 23}, "zzzzzzzzzzzzzzzzzzzzzzzzzz" => {"complete" => 3, "downloaded" => 26, "incomplete" => 1}}}
    # @return [Hash] The method returns a hash with the scraped data
    def scrape
      unhex_info_hash = @info_hash.map{|x| Binascii.a2b_hex(x)}
      params = unhex_info_hash.map{|h| "info_hash=#{CGI.escape(h.to_s)}"}.join('&')
      begin
        HTTParty.get(@tracker, :query => params, :headers => {'User-Agent' => "btscraper #{VERSION}"}, :timeout => 10).body.bdecode
      rescue HTTParty::Error => e
        raise BTScraperError, e
      end
    end
  end
end