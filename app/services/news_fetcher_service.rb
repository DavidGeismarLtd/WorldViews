# Service to fetch news from NewsAPI.org
class NewsFetcherService
  include HTTParty
  base_uri "https://newsapi.org/v2"

  def initialize(api_key: ENV["NEWS_API_KEY"])
    @api_key = api_key
  end

  def fetch_and_store_news(category: "general", limit: 10)
    Rails.logger.info "📰 Fetching news from NewsAPI (category: #{category}, limit: #{limit})"

    articles = fetch_top_headlines(category: category, limit: limit)

    if articles.empty?
      Rails.logger.warn "⚠️  No articles fetched from NewsAPI"
      return { new: [], updated: [], skipped: [], total: 0 }
    end

    process_and_store_articles(articles)
  end

  # Fetch news since last successful fetch
  def fetch_latest_news(categories: [ "general", "technology", "business" ], limit_per_category: 20)
    last_fetch = NewsStory.maximum(:published_at) || 7.days.ago
    Rails.logger.info "📰 Fetching news since #{last_fetch}"

    all_results = { new: [], updated: [], skipped: [], total: 0 }

    categories.each do |category|
      Rails.logger.info "  📂 Category: #{category}"
      articles = fetch_top_headlines(category: category, limit: limit_per_category)

      # Filter to only articles newer than our last fetch
      new_articles = articles.select do |article|
        published_at = Time.parse(article[:published_at]) rescue nil
        published_at && published_at > last_fetch
      end

      Rails.logger.info "  📊 Found #{new_articles.count} new articles (out of #{articles.count} total)"

      results = process_and_store_articles(new_articles)

      # Merge results
      all_results[:new] += results[:new]
      all_results[:updated] += results[:updated]
      all_results[:skipped] += results[:skipped]
      all_results[:total] += results[:total]
    end

    Rails.logger.info "✅ Fetch complete: #{all_results[:new].count} new, #{all_results[:updated].count} updated, #{all_results[:skipped].count} skipped"
    all_results
  end


  def fetch_top_headlines(category: "general", limit: 10)
    # Require API key - no mock data fallback in production
    if @api_key.blank?
      error_msg = "❌ NEWS_API_KEY is not set! Cannot fetch news."
      Rails.logger.error error_msg
      raise ArgumentError, error_msg
    end

    response = self.class.get("/top-headlines", query: {
      apiKey: @api_key,
      country: "us",
      category: category,
      pageSize: limit
    })

    binding.pry
    if response.success?
      parse_response(response)
    else
      Rails.logger.error "❌ NewsAPI error: #{response.code} - #{response.message}"
      []
    end
  end

  private

  def process_and_store_articles(articles)
    new_stories = []
    updated_stories = []
    skipped_stories = []

    articles.each do |article_data|
      story = NewsStory.find_or_initialize_by(external_id: article_data[:external_id])

      if story.new_record?
        story.assign_attributes(article_data)
        if story.save
          Rails.logger.info "  ✓ NEW: #{story.headline[0..60]}..."
          new_stories << story
        else
          Rails.logger.error "  ✗ FAILED: #{story.errors.full_messages.join(', ')}"
        end
      elsif story.headline != article_data[:headline] || story.summary != article_data[:summary]
        story.assign_attributes(article_data)
        if story.save
          Rails.logger.info "  ↻ UPDATED: #{story.headline[0..60]}..."
          updated_stories << story
        end
      else
        Rails.logger.debug "  ⊙ SKIPPED: #{story.headline[0..60]}..."
        skipped_stories << story
      end
    end

    {
      new: new_stories,
      updated: updated_stories,
      skipped: skipped_stories,
      total: articles.count
    }
  end

  # Fetch news since a specific date (for incremental updates)
  def fetch_since(from_date:, category: "general", limit: 100)
    if @api_key.blank?
      error_msg = "❌ NEWS_API_KEY is not set! Cannot fetch news."
      Rails.logger.error error_msg
      raise ArgumentError, error_msg
    end

    Rails.logger.info "📰 Fetching news since #{from_date} (category: #{category})"

    response = self.class.get("/everything", query: {
      apiKey: @api_key,
      from: from_date.iso8601,
      language: "en",
      sortBy: "publishedAt",
      pageSize: limit
    })

    if response.success?
      parse_response(response)
    else
      Rails.logger.error "❌ NewsAPI error: #{response.code} - #{response.message}"
      []
    end
  end

  private

  def mock_response(category, limit)
    # Mock NewsAPI response structure
    {
      "status" => "ok",
      "totalResults" => 10,
      "articles" => [
        {
          "source" => { "id" => "techcrunch", "name" => "TechCrunch" },
          "author" => "Sarah Perez",
          "title" => "AI Startup Raises $500M to Build 'ChatGPT Killer'",
          "description" => "A new AI startup backed by Silicon Valley heavyweights has raised $500 million to develop what they claim will be a revolutionary language model that surpasses ChatGPT.",
          "url" => "https://techcrunch.com/2024/ai-startup-funding",
          "urlToImage" => "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800",
          "publishedAt" => 2.hours.ago.iso8601,
          "content" => "The startup, founded by former OpenAI researchers, claims their approach will be more efficient and accurate..."
        },
        {
          "source" => { "id" => "cnn", "name" => "CNN" },
          "author" => "Jake Tapper",
          "title" => "Congress Passes Controversial Tech Regulation Bill",
          "description" => "In a rare bipartisan vote, Congress has passed sweeping legislation to regulate big tech companies, including new privacy protections and antitrust measures.",
          "url" => "https://cnn.com/2024/tech-regulation-bill",
          "urlToImage" => "https://images.unsplash.com/photo-1555374018-13a8994ab246?w=800",
          "publishedAt" => 4.hours.ago.iso8601,
          "content" => "The bill, which passed 312-118 in the House, represents the most significant tech regulation in decades..."
        },
        {
          "source" => { "id" => "bloomberg", "name" => "Bloomberg" },
          "author" => "Emily Chang",
          "title" => "Tesla Stock Surges 15% on New Battery Technology Announcement",
          "description" => "Tesla shares jumped after the company unveiled a breakthrough in battery technology that could double electric vehicle range while cutting costs in half.",
          "url" => "https://bloomberg.com/2024/tesla-battery-breakthrough",
          "urlToImage" => "https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=800",
          "publishedAt" => 6.hours.ago.iso8601,
          "content" => "CEO Elon Musk announced the new solid-state battery technology at a surprise event..."
        },
        {
          "source" => { "id" => "fox-news", "name" => "Fox News" },
          "author" => "Tucker Carlson",
          "title" => "Border Crisis Deepens as Migrant Encounters Hit Record High",
          "description" => "U.S. Customs and Border Protection reported a record 300,000 migrant encounters at the southern border last month, sparking renewed debate over immigration policy.",
          "url" => "https://foxnews.com/2024/border-crisis-record",
          "urlToImage" => "https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=800",
          "publishedAt" => 8.hours.ago.iso8601,
          "content" => "The surge in border crossings has overwhelmed processing facilities and reignited political tensions..."
        },
        {
          "source" => { "id" => "the-verge", "name" => "The Verge" },
          "author" => "Nilay Patel",
          "title" => "Apple Announces Vision Pro 2 with Mind-Reading Features",
          "description" => "Apple's next-generation mixed reality headset will include neural interface technology that can detect user intentions through brain activity patterns.",
          "url" => "https://theverge.com/2024/apple-vision-pro-2",
          "urlToImage" => "https://images.unsplash.com/photo-1617802690992-15d93263d3a9?w=800",
          "publishedAt" => 10.hours.ago.iso8601,
          "content" => "The Vision Pro 2, priced at $2,999, represents Apple's most ambitious product launch since the original iPhone..."
        },
        {
          "source" => { "id" => "politico", "name" => "Politico" },
          "author" => "Jonathan Martin",
          "title" => "Supreme Court to Hear Landmark Social Media Free Speech Case",
          "description" => "The Supreme Court has agreed to hear a case that could reshape how the First Amendment applies to content moderation on social media platforms.",
          "url" => "https://politico.com/2024/supreme-court-social-media",
          "urlToImage" => "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=800",
          "publishedAt" => 12.hours.ago.iso8601,
          "content" => "Legal experts say the case could have far-reaching implications for online speech and platform liability..."
        },
        {
          "source" => { "id" => "wsj", "name" => "Wall Street Journal" },
          "author" => "Greg Ip",
          "title" => "Federal Reserve Signals Interest Rate Cuts Coming in 2024",
          "description" => "Fed Chair Jerome Powell indicated the central bank is prepared to lower interest rates as inflation shows signs of cooling to the 2% target.",
          "url" => "https://wsj.com/2024/fed-rate-cuts-signal",
          "urlToImage" => "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800",
          "publishedAt" => 14.hours.ago.iso8601,
          "content" => "The announcement sent stock markets soaring as investors anticipated easier monetary policy ahead..."
        },
        {
          "source" => { "id" => "wired", "name" => "Wired" },
          "author" => "Steven Levy",
          "title" => "Quantum Computer Achieves 'Impossible' Calculation in Seconds",
          "description" => "Google's quantum computer has solved a problem that would take classical supercomputers thousands of years, marking a major milestone in quantum supremacy.",
          "url" => "https://wired.com/2024/quantum-computing-breakthrough",
          "urlToImage" => "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800",
          "publishedAt" => 16.hours.ago.iso8601,
          "content" => "The achievement demonstrates quantum computing's potential to revolutionize fields from cryptography to drug discovery..."
        },
        {
          "source" => { "id" => "nyt", "name" => "New York Times" },
          "author" => "Maggie Haberman",
          "title" => "Major Climate Agreement Reached at Global Summit",
          "description" => "Nearly 200 countries have agreed to triple renewable energy capacity by 2030 in what leaders are calling the most ambitious climate accord since Paris.",
          "url" => "https://nytimes.com/2024/climate-summit-agreement",
          "urlToImage" => "https://images.unsplash.com/photo-1569163139394-de4798aa62b6?w=800",
          "publishedAt" => 18.hours.ago.iso8601,
          "content" => "The agreement includes binding commitments to phase out fossil fuel subsidies and invest $1 trillion in clean energy..."
        },
        {
          "source" => { "id" => "ars-technica", "name" => "Ars Technica" },
          "author" => "Ron Amadeo",
          "title" => "SpaceX Successfully Lands Starship on Mars in Historic Mission",
          "description" => "SpaceX's Starship has successfully landed on Mars, marking humanity's first crewed mission to the Red Planet and a major step toward establishing a permanent settlement.",
          "url" => "https://arstechnica.com/2024/spacex-mars-landing",
          "urlToImage" => "https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=800",
          "publishedAt" => 20.hours.ago.iso8601,
          "content" => "The crew of six astronauts will spend 18 months on Mars conducting research and testing life support systems..."
        }
      ]
    }
  end

  def parse_response(response)
    return [] unless response["status"] == "ok"
    return [] unless response["articles"].present?

    response["articles"].map do |article|
      {
        external_id: generate_external_id(article),
        headline: article["title"],
        summary: article["description"],
        full_content: article["content"],
        source: article.dig("source", "name") || "Unknown",
        source_url: article["url"],
        image_url: article["urlToImage"],
        published_at: article["publishedAt"],
        category: determine_category(article),
        metadata: {
          author: article["author"],
          source_id: article.dig("source", "id")
        }
      }
    end
  end

  def generate_external_id(article)
    # Create a unique ID from URL or title + published date
    if article["url"].present?
      Digest::MD5.hexdigest(article["url"])
    else
      Digest::MD5.hexdigest("#{article['title']}-#{article['publishedAt']}")
    end
  end

  def determine_category(article)
    # NewsAPI doesn't always return category, so we'll infer or use default
    source_name = article.dig("source", "name")&.downcase || ""

    case source_name
    when /tech|wired|verge|ars/
      "technology"
    when /business|financial|bloomberg|wsj/
      "business"
    when /cnn|fox|msnbc|politico/
      "politics"
    when /science|nature|scientific/
      "science"
    else
      "general"
    end
  end
end
