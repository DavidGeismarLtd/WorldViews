class ScraperAlertMailer < ApplicationMailer
  default from: "worldviews-alerts@example.com"

  def scraping_failed(url, domain)
    @url = url
    @domain = domain
    @timestamp = Time.current

    mail(
      to: "dageismar@gmail.com",
      subject: "🚨 Article Scraper Failed: #{domain}"
    )
  end
end

