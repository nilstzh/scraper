require "minitest/autorun"

class Clients::SeleniumTest < Minitest::Test
  def test_get_method_returns_page_content
    mock_driver = Minitest::Mock.new
    mock_navigate = Minitest::Mock.new

    mock_driver.expect(:navigate, mock_navigate)
    mock_navigate.expect(:to, nil, ["http://example.com"])
    mock_driver.expect(:page_source, "<html><body><h1>Selenium Title</h1></body></html>")
    mock_driver.expect(:quit, nil)

    Clients::Selenium.stub :driver, mock_driver do
      result = Clients::Selenium.get("http://example.com")
      assert_equal "<html><body><h1>Selenium Title</h1></body></html>", result
    end

    mock_driver.verify
    mock_navigate.verify
  end
end
