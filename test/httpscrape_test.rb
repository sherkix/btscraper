require_relative 'test_helper'

class TestHTTPScrape < Minitest::Test
  def setup
    @scrape_object = BTScraper::HTTPScrape.new('https://tracker.pmman.tech:443/scrape', '1fd1005123e1aaf9139fe07849bd1fe19139c0a5')
  end

  def test_scrape
    assert_kind_of Hash, @scrape_object.scrape, 'Failure. The object must be a Hash'
  end
end