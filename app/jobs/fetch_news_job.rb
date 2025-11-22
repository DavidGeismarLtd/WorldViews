# Background job to fetch news from NewsAPI
class FetchNewsJob < ApplicationJob
  queue_as :default

  def perform(category: "general", limit: 10)
    Rails.logger.info "🔄 Starting FetchNewsJob (category: #{category}, limit: #{limit})"

    service = NewsFetcherService.new
    stories = service.fetch_and_store_news(category: category, limit: limit)

    Rails.logger.info "✅ FetchNewsJob complete: #{stories.count} stories processed"

    # Optionally trigger interpretation generation for new stories
    stories.each do |story|
      GenerateInterpretationsJob.perform_later(story.id)
    end
  rescue StandardError => e
    Rails.logger.error "❌ FetchNewsJob failed: #{e.message}"
    raise
  end
end

