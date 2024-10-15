class Scraper
  def initialize(url, fields)
    @url = url

    @css_selectors = fields.to_h&.except(:meta)
    @meta_names = fields&.dig(:meta)
  end

  def run
    raise(ScraperError, "Invalid URL") unless valid_url?(@url)
    raise(ScraperError, "Missing `fields` parameters") if @css_selectors.blank? && @meta_names.blank?

    fetch_page
      .then { |page| scrape(page) }
  end

  private

  def fetch_page
    driver = selenium_driver()
    driver.navigate.to(@url)
    page = driver.page_source
    driver.quit

    page
  end

  def scrape(page)
    document = Nokogiri::HTML(page)
    data = {}

    document
      .tap { |doc| data.merge!(scrape_by_selectors(doc)) }
      .then { |doc| data.merge!(scrape_by_meta_names(doc)) }

    data
  end

  def scrape_by_selectors(doc)
    return {} if @css_selectors.blank?

    @css_selectors.each_with_object({}) do |(label, selector), result|
      result[label] = get_text(doc, selector)
    end
  end

  def scrape_by_meta_names(doc)
    return {} if @meta_names.blank?

    results = @meta_names.each_with_object({}) do |name, result|
      result[name] = get_meta_content(doc, name)
    end

    { meta: results }
  end

  def get_text(doc, selector)
    doc.at_css(selector).text
  end

  def get_meta_content(doc, name)
    doc.at_css("meta[name='#{name}']").attributes["content"].value
  end

  def valid_url?(string)
    return false if string.blank?
    return false unless string.match?(/^https?:\/\/[\w\d-]+\.[\w\d-]+/)

    true
  end

  def selenium_driver
    user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"\
                 "Chrome/92.0.4515.159 Safari/537.36"

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--user-agent=#{user_agent}")
    Selenium::WebDriver.for :chrome, options: options
  end

  class ScraperError < StandardError; end
end
