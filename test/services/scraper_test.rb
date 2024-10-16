require "minitest/autorun"

class ScraperTest < Minitest::Test
  def setup
    @valid_url = "http://example.com"
    @invalid_url = "invalid_url"
    @fields = { title: "h1", description: ".desc", meta: [ "author", "keywords" ] }
    @scraper = Scraper.new(@valid_url, @fields)
  end

  def test_initialize
    assert_equal @valid_url, @scraper.instance_variable_get(:@url)
    assert_equal({ title: "h1", description: ".desc" }, @scraper.instance_variable_get(:@css_selectors))
    assert_equal [ "author", "keywords" ], @scraper.instance_variable_get(:@meta_names)
  end

  def test_run_with_invalid_url
    scraper = Scraper.new(@invalid_url, @fields)
    assert_raises(Scraper::ScraperError, "Invalid URL") { scraper.run }
  end

  def test_run_with_missing_fields
    scraper = Scraper.new(@valid_url, {})
    assert_raises(Scraper::ScraperError, "Missing `fields` parameters") { scraper.run }
  end

  def test_valid_url
    assert @scraper.send(:valid_url?, "http://example.com")
    refute @scraper.send(:valid_url?, "invalid_url")
    refute @scraper.send(:valid_url?, "")
  end

  def test_fetch_page_with_cache
    cached_page = "<html><body><h1>Cached Title</h1></body></html>"
    Rails.cache.stub(:read, cached_page) do
      assert_equal cached_page, @scraper.send(:fetch_page)
    end
  end

  def test_fetch_page_with_httparty_client
    ENV.stub(:[], 'httparty') do
      fetched_page = "<html><body><h1>Title from HTTParty</h1></body></html>"

      Clients::Httparty.stub(:get, fetched_page) do
        Rails.cache.stub(:read, nil) do
          Rails.cache.stub(:write, true) do
            assert_equal fetched_page, @scraper.send(:fetch_page)
          end
        end
      end
    end
  end

  def test_fetch_page_with_selenium_client
    ENV.stub(:[], 'selenium') do
      fetched_page = "<html><body><h1>Title from Selenium</h1></body></html>"

      Clients::Selenium.stub(:get, fetched_page) do
        Rails.cache.stub(:read, nil) do
          Rails.cache.stub(:write, true) do
            assert_equal fetched_page, @scraper.send(:fetch_page)
          end
        end
      end
    end
  end

  def test_http_client_raises_error_for_unknown_client
    ENV.stub(:[], 'unknown_client') do
      assert_raises(RuntimeError, "Unknown HTTP client specified: unknown_client") { @scraper.send(:http_client) }
    end
  end

  def test_scrape_by_selectors
    page = Nokogiri::HTML("<html><body><h1>Title</h1><p class=\"desc\">Description</p></body></html>")
    result = @scraper.send(:scrape_by_selectors, page)
    assert_equal({ title: "Title", description: "Description" }, result)
  end

  def test_scrape_by_meta_names
    page = Nokogiri::HTML("<html><head><meta name='author' content='John Doe'><meta name='keywords' content='ruby, scraping'></head></html>")
    result = @scraper.send(:scrape_by_meta_names, page)
    expected_meta = { meta: { "author" => "John Doe", "keywords" => "ruby, scraping" } }
    assert_equal expected_meta, result
  end

  def test_scrape
    page = "<html><head><meta name='author' content='John Doe'><meta name='keywords' content='ruby, scraping'></head>"\
           "<body><h1>Title</h1><p class=\"desc\">Description</p></body></html>"
    result = @scraper.send(:scrape, page)
    expected_result = { title: "Title", description: "Description", meta: { "author" => "John Doe", "keywords" => "ruby, scraping" } }
    assert_equal expected_result, result
  end

  def test_cache_key_generation
    expected_cache_key = "scraper:page:#{Digest::MD5.hexdigest(@valid_url)}"
    assert_equal expected_cache_key, @scraper.send(:cache_key)
  end
end
