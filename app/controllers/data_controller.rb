class DataController < ApplicationController
  def scrape
    scraper = Scraper.new(data_params[:url], data_params[:fields])
    scraped_data = scraper.run
  rescue Scraper::ScraperError => error
    render json: { error: error }, status: :unprocessable_entity
  else
    render json: scraped_data
  end

  private

  def data_params
    @data_params ||= params.require(:data).permit(:url, fields: {})
  end
end
