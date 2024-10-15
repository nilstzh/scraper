require "minitest/autorun"

class DataControllerTest < ActionController::TestCase
  def setup
    @valid_url = "http://example.com"
    @invalid_url = "invalid_url"
    @valid_fields = { title: "h1", description: ".desc" }
    @scraper_mock = Minitest::Mock.new
  end

  def test_scrape_success
    scraped_data = { title: "Sample Title", description: "Sample Description" }
    @scraper_mock.expect(:run, scraped_data)

    Scraper.stub :new, @scraper_mock do
      post :scrape, params: { data: { url: @valid_url, fields: @valid_fields } }

      assert_response :success
      assert_equal scraped_data.to_json, @response.body
    end

    @scraper_mock.verify
  end

  def test_scrape_invalid_url
    @scraper_mock.expect(:run, nil) { raise Scraper::ScraperError, "Invalid URL" }

    Scraper.stub :new, @scraper_mock do
      post :scrape, params: { data: { url: @invalid_url, fields: @valid_fields } }

      assert_response :unprocessable_entity
      expected_error = { error: "Invalid URL" }.to_json
      assert_equal expected_error, @response.body
    end

    @scraper_mock.verify
  end

  def test_scrape_missing_url
    @scraper_mock.expect(:run, nil) { raise Scraper::ScraperError, "Invalid URL" }

    Scraper.stub :new, @scraper_mock do
      post :scrape, params: { data: { fields: @valid_fields } }

      assert_response :unprocessable_entity
      expected_error = { error: "Invalid URL" }.to_json
      assert_equal expected_error, @response.body
    end

    @scraper_mock.verify
  end

  def test_scrape_missing_fields
    @scraper_mock.expect(:run, nil) { raise Scraper::ScraperError, "Missing `fields` parameters" }

    Scraper.stub :new, @scraper_mock do
      post :scrape, params: { data: { url: @valid_url } }

      assert_response :unprocessable_entity
      expected_error = { error: "Missing `fields` parameters" }.to_json
      assert_equal expected_error, @response.body
    end

    @scraper_mock.verify
  end
end
