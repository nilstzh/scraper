require "minitest/autorun"

class Clients::HttpartyTest < Minitest::Test
  def test_get_method_returns_page_content
    mock_response = Minitest::Mock.new
    mock_response.expect(:body, "<html><body><h1>HTTParty Title</h1></body></html>")

    HTTParty.stub :get, mock_response do
      result = Clients::Httparty.get("http://example.com")
      assert_equal "<html><body><h1>HTTParty Title</h1></body></html>", result
    end

    mock_response.verify
  end
end
