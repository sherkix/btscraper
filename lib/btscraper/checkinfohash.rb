module BTScraper
  Sha1_regex = /^[0-9a-f]{40}$/ # Regex to check SHA1 infohashes

  # This method checks if the infohashes are valid
  # @raise [BTScraperError] If the infohash is invalid
  def self.check_info_hash(info_hash)
    info_hash.each{|x| raise BTScraperError, 'Invalid infohash provided' unless x.match?(Sha1_regex)}
  end
  
end