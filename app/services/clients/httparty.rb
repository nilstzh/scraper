class Clients::Httparty
  def self.get(url)
    response = HTTParty.get(url)
    page = response.body
  end
end
