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
    driver = Selenium::WebDriver.for :chrome
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

  class ScraperError < StandardError; end
end
