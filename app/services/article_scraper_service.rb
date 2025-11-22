# Service to scrape full article content from news URLs
class ArticleScraperService
  include HTTParty

  def initialize(url)
    @url = url
  end

  def scrape_content
    return nil if @url.blank?

    Rails.logger.info "🔍 Scraping article: #{@url}"

    response = self.class.get(@url, {
      headers: {
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
      },
      timeout: 10
    })

    return nil unless response.success?

    doc = Nokogiri::HTML(response.body)
    
    # Try multiple strategies to extract article content
    content = extract_article_content(doc)
    
    if content.present?
      Rails.logger.info "  ✅ Scraped #{content.length} characters"
      content
    else
      Rails.logger.warn "  ⚠️  Could not extract article content"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "  ❌ Scraping failed: #{e.message}"
    nil
  end

  private

  def extract_article_content(doc)
    # Strategy 1: Look for common article content selectors
    article_selectors = [
      'article',
      '[role="article"]',
      '.article-content',
      '.article-body',
      '.post-content',
      '.entry-content',
      '.story-body',
      'main article',
      '#article-body'
    ]

    article_selectors.each do |selector|
      element = doc.at_css(selector)
      next unless element

      # Extract text from paragraphs within the article
      paragraphs = element.css('p').map(&:text).reject(&:blank?)
      next if paragraphs.empty?

      content = paragraphs.join("\n\n")
      return content if content.length > 200 # Minimum viable article length
    end

    # Strategy 2: Find all paragraphs in the main content area
    main_content = doc.at_css('main') || doc.at_css('body')
    return nil unless main_content

    paragraphs = main_content.css('p').map(&:text).reject(&:blank?)
    return nil if paragraphs.empty?

    # Filter out likely navigation/footer paragraphs (too short)
    article_paragraphs = paragraphs.select { |p| p.length > 50 }
    return nil if article_paragraphs.empty?

    article_paragraphs.join("\n\n")
  end
end

