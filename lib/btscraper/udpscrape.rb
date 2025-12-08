require 'uri'
require 'socket'
require 'timeout'

module BTScraper

  Connection_id = 0x41727101980 # Magic Constant
  Actionconn = 0 # Connection Request
  Actionscrape = 2 # Scrape Request
  Actionerr = 3 # Scrape Error
  Defaulttimeout = 15 # Default timeout is 15s
  Retries = 8 # Maximum number of retransmission
  
  # @author sherkix 
  # @see https://bittorrent.org/beps/bep_0015.html BEP 15
  # This class permits you to scrape an UDP torrent tracker according to the BEP 15
  class UDPScrape
    
    attr_reader :tracker, :info_hash, :hostname, :port
    # @!attribute [r] tracker
    #  @return [String] returns tracker full url
    #  
    # @!attribute [r] info_hash
    #  @return [Array<String>] returns array of infohashes
    #   
    # @!attribute [r] hostname
    #  @return [String] returns tracker's hostname
    #  
    # @!attribute [r] port
    #  @return [Integer] returns tracker's port
    #
    # Create a new UDPScrape object 
    # 
    # @param tracker [String] Bittorrent UDP tracker server
    # @param info_hash [Array<String>, String] Array of infohashes or single infohash
    #
    # 
    # @raise [TypeError] if wrong type of argument is provided
    # @raise [BTScraperError] if the infohashes provided are more than 74
    # 
    # @example Default usage
    #  scrape_object = BTScraper::UDPScrape.new('udp://example.com:3000/announce', ['c22b5f9178342609428d6f51b2c5af4c0bde6a42'], ['aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d'])
    #  scrape_object.scrape
    def initialize(tracker, info_hash)
      unless tracker.instance_of? String
        raise TypeError, "String excpected, got #{tracker.class}"
      end
      unless info_hash.instance_of? String or info_hash.instance_of? Array
        raise TypeError, "String or Array excpected, got #{info_hash.class}"
      end
      
      # Maximum number of infohashes is 74
      if info_hash.instance_of? Array and info_hash.count > 74
        raise BTScraperError, 'The number of infohashes must be less than 74'
      end

      if info_hash.instance_of? String
        info_hash.downcase!
        BTScraper.check_info_hash Array(info_hash)
      else
        info_hash.map(&:downcase!)
        BTScraper.check_info_hash info_hash
      end
      @tracker = tracker 
      @hostname = URI(@tracker).hostname
      @port = URI(@tracker).port 
      @info_hash = Array(info_hash) 
    end
    # @example Response example
    #  {tracker: "udp://example.com:3000/announce", scraped_data: [{infohash: "c22b5f9178342609428d6f51b2c5af4c0bde6a42", seeders: 20, completed: 1000, leechers: 30}, {infohash: "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d", seeders: 350, completed: 12000, leechers: 23}]}
    # @return [Hash] The method returns a hash with the scraped data
    # @raise [BTScraperError] If the response is less than 8 bytes
    # @raise [BTScraperError] If the scraping request fails
    # @raise [BTScraperError] If the tracker responds with a different transaction_id provided by the client
    # @raise [BTScraperError] After 8 timeouts
    def scrape
      attempt = 0
      client = connect_to_tracker
      transaction_id = rand_transaction_id
      buffer = [get_connection_id, Actionscrape, transaction_id].pack('Q>NN')
      @info_hash.each{|x| buffer << x.split.pack('H*')}
      begin
        client.send buffer, 0
        Timeout::timeout(Defaulttimeout * 2**attempt) do
          response = client.recvfrom(4096)
          if response[0].bytesize < 8
            raise BTScraperError, 'The response from the tracker is less than 8 bytes'
          end
          @unpacked_response = response[0].unpack('N*')
          if @unpacked_response[0] == Actionerr
            raise BTScraperError, 'Scrape request failed'
          end
          unless @unpacked_response[1] == transaction_id
            raise BTScraperError, 'Invalid transaction id got from tracker'
          end
        end
      rescue Timeout::Error
        attempt+=1
        puts "#{attempt} Request to #{@hostname} timed out, retying after #{Defaulttimeout * 2**attempt}s"
        retry if attempt <= Retries
        raise BTScraperError, 'Max retries exceeded'
      ensure
        client.close
      end
      hash = {tracker: @tracker, scraped_data:[]}
      create_scrape_hash @info_hash, @unpacked_response, hash
    end
    
    private

    # @return [Array<Integer>] This method makes a request to the bittorrent tracker to get a connection_id
    def get_connection_id
      attempt = 0
      client = connect_to_tracker
      transaction_id = rand_transaction_id
      buffer = [Connection_id, Actionconn, transaction_id].pack('Q>N*')
      begin
        client.send buffer, 0
        Timeout::timeout(Defaulttimeout * 2**attempt) do 
          response = client.recvfrom(16)
          if response[0].bytesize > 16
            raise BTScraperError, 'The response from the tracker is greater than 16 bytes'
          end
          @unpacked_response = response[0].unpack('NNQ>')
          unless @unpacked_response[0] == Actionconn
            raise BTScraperError, "The action number received from the tracker was not #{Actionconn}"
          end
          unless @unpacked_response[1] == transaction_id
            raise BTScraperError, 'Invalid transaction id got from tracker'
          end
        end
      rescue Timeout::Error
        attempt+=1
        puts "#{attempt} Request to #{@hostname} timed out, retrying after #{Defaulttimeout * 2**attempt}s"
        retry if attempt <= Retries
        raise BTScraperError, 'Max retries exceeded'
      ensure
        client.close
      end
      @unpacked_response[2]
    end

    def connect_to_tracker
      client = UDPSocket.new
      client.connect(@hostname, @port)
      client
    end

    def rand_transaction_id
      rand(0..4294967295)
    end

    def create_scrape_hash(info_hash, response, hash)
      i = 2
      info_hash.each do |x|
        temp_hash = {infohash: x}
        temp_hash[:seeders] = response[i] 
        temp_hash[:completed] = response[i+1]
        temp_hash[:leechers] = response[i+2]
        i+=3
        hash[:scraped_data].push temp_hash
      end
      hash
    end
  end
end