require_relative 'test_helper'

class TestUDPScrape < Minitest::Test
  def setup
    @scrape_object = BTScraper::UDPScrape.new('udp://tracker.opentrackr.org:1337/announce', '1fd1005123e1aaf9139fe07849bd1fe19139c0a5')
  end

  def test_scrape
    assert_kind_of Hash, @scrape_object.scrape, 'Failure. The object must be a Hash'
  end
end