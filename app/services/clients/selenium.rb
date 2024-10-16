class Clients::Selenium
  def self.get(url)
    driver = driver()
    driver.navigate.to(url)
    page = driver.page_source
    driver.quit

    page
  end

  def self.driver
    user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"\
                 "Chrome/92.0.4515.159 Safari/537.36"

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--user-agent=#{user_agent}")
    Selenium::WebDriver.for :chrome, options: options
  end
end
