require 'watir'
require 'pry'
require 'bundler'
Bundler.require

class ShareScraper
  def run
    set_driver
    get_data
    update_google_sheets
  end
  
  def set_driver
    options = Selenium::WebDriver::Chrome::Options.new
    # options.add_option(:detach, true)
    options.add_argument("start-maximized")
    @browser = Watir::Browser.new :chrome, :options => options
  end
  
  def get_data
    date = Time.now.strftime("%d/%m/%Y")
    shares = %w[TIET11 B3SA3 VVAR3 ITUB3 MGLU3]
    @data = []
    
    url = 'https://statusinvest.com.br/'
    @browser.goto(url)
    
    shares.map do |share|
      @browser.link(class: 'main-search').click
      @browser.span(class: 'twitter-typeahead').input(class: %w[Typeahead-input input tt-input]).send_keys(share)
      sleep(2)
      @browser.div(class: 'Typeahead-menu').click if @browser.div(class: 'Typeahead-menu').exists?
      sleep(2)
      current_value = @browser.div(title: 'Valor atual do ativo').strong(class: 'value').text
      @data << [share, current_value, date]
    end
  end
  
  def update_google_sheets
    session = GoogleDrive::Session.from_config("config.json")
    spreadsheet = session.spreadsheet_by_url('https://docs.google.com/spreadsheets/d/1UCqFaodcgcz4wpjbIrv9sOfHUkACk9G7ADofTGrsHf4/edit#gid=0')
    worksheet = spreadsheet.worksheets.first
    worksheet.insert_rows(worksheet.num_rows + 1, @data)
    worksheet.save
  end
end

ss = ShareScraper.new
ss.run
