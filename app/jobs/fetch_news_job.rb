# Background job to fetch news from NewsAPI
class FetchNewsJob < ApplicationJob
  queue_as :default

  # Fetch latest news across multiple categories (smart sync)
  def perform(mode: :latest, categories: nil, limit_per_category: 20)
    Rails.logger.info "🔄 Starting FetchNewsJob (mode: #{mode})"

    service = NewsFetcherService.new

    results = case mode
    when :latest
      # Smart mode: fetch only new stories since last fetch
      categories ||= %w[general technology business]
      service.fetch_latest_news(categories: categories, limit_per_category: limit_per_category)
    when :single_category
      # Legacy mode: fetch single category
      category = categories&.first || "general"
      service.fetch_and_store_news(category: category, limit: limit_per_category)
    else
      raise ArgumentError, "Unknown mode: #{mode}"
    end

    # Log statistics
    new_count = results[:new]&.count || 0
    updated_count = results[:updated]&.count || 0
    skipped_count = results[:skipped]&.count || 0

    Rails.logger.info "✅ FetchNewsJob complete:"
    Rails.logger.info "   📊 #{new_count} new stories"
    Rails.logger.info "   📊 #{updated_count} updated stories"
    Rails.logger.info "   📊 #{skipped_count} skipped (duplicates)"

    # Optionally trigger interpretation generation for new stories only
    # (Don't regenerate for updated or skipped stories)
    if results[:new].present?
      results[:new].each do |story|
        GenerateInterpretationsJob.perform_later(story.id)
      end
      Rails.logger.info "   🤖 Queued interpretation generation for #{new_count} new stories"
    end

    results
  end
end
