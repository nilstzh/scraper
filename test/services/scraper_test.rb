require 'minitest/autorun'

class ScraperTest < Minitest::Test
  def setup
    @valid_url = "http://example.com"
    @invalid_url = "invalid_url"
    @fields = { title: 'h1', description: '.desc', meta: ['author', 'keywords'] }
    @scraper = Scraper.new(@valid_url, @fields)
  end

  def test_initialize
    assert_equal @valid_url, @scraper.instance_variable_get(:@url)
    assert_equal({ title: 'h1', description: '.desc' }, @scraper.instance_variable_get(:@css_selectors))
    assert_equal ['author', 'keywords'], @scraper.instance_variable_get(:@meta_names)
  end

  def test_run_with_invalid_url
    scraper = Scraper.new(@invalid_url, @fields)
    assert_raises(Scraper::ScraperError, 'Invalid URL') { scraper.run }
  end

  def test_run_with_missing_fields
    scraper = Scraper.new(@valid_url, {})
    assert_raises(Scraper::ScraperError, 'Missing `fields` parameters') { scraper.run }
  end

  def test_valid_url
    assert @scraper.send(:valid_url?, "http://example.com")
    refute @scraper.send(:valid_url?, "invalid_url")
    refute @scraper.send(:valid_url?, "")
  end

  def test_fetch_page
    mock_driver = Minitest::Mock.new
    mock_navigate = Minitest::Mock.new

    mock_driver.expect(:navigate, mock_navigate)
    mock_driver.expect(:quit, nil)

    mock_navigate.expect(:to, nil, [@valid_url])

    mock_driver.expect(:page_source, "<html><body><h1>Title</h1></body></html>")

    Selenium::WebDriver.stub :for, mock_driver do
      assert_equal "<html><body><h1>Title</h1></body></html>", @scraper.send(:fetch_page)
    end

    mock_driver.verify
    mock_navigate.verify
  end

  def test_scrape_by_selectors
    page = Nokogiri::HTML("<html><body><h1>Title</h1><p class=\"desc\">Description</p></body></html>")
    result = @scraper.send(:scrape_by_selectors, page)
    assert_equal({ title: 'Title', description: 'Description' }, result)
  end

  def test_scrape_by_meta_names
    page = Nokogiri::HTML("<html><head><meta name='author' content='John Doe'><meta name='keywords' content='ruby, scraping'></head></html>")
    result = @scraper.send(:scrape_by_meta_names, page)
    expected_meta = { meta: { 'author' => 'John Doe', 'keywords' => 'ruby, scraping' } }
    assert_equal expected_meta, result
  end

  def test_scrape
    page = "<html><head><meta name='author' content='John Doe'><meta name='keywords' content='ruby, scraping'></head>"\
           "<body><h1>Title</h1><p class=\"desc\">Description</p></body></html>"
    result = @scraper.send(:scrape, page)
    expected_result = { title: 'Title', description: 'Description', meta: { 'author' => 'John Doe', 'keywords' => 'ruby, scraping' } }
    assert_equal expected_result, result
  end
end
