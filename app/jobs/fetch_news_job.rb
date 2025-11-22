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

    # Generate interpretations for new stories only (synchronously for the 6 base personas)
    # (Don't regenerate for updated or skipped stories)
    if results[:new].present?
      Rails.logger.info "   🤖 Generating interpretations for #{new_count} new stories..."

      # Get all official base personas (the 6 core personas)
      official_personas = Persona.active.official.ordered.to_a

      generated_count = 0
      failed_count = 0

      results[:new].each do |story|
        official_personas.each do |persona|
          # Skip if interpretation already exists
          next if Interpretation.exists?(news_story: story, persona: persona)

          begin
            # Generate interpretation synchronously
            InterpretationGeneratorService.new(
              news_story: story,
              persona: persona
            ).generate!
            generated_count += 1
          rescue => e
            # Log error but continue with other interpretations
            Rails.logger.error "   ❌ Failed to generate interpretation for #{persona.name} on story #{story.id}: #{e.message}"
            failed_count += 1
          end
        end
      end

      Rails.logger.info "   ✅ Generated #{generated_count} interpretations (#{official_personas.count} personas × #{new_count} stories)"
      Rails.logger.warn "   ⚠️  #{failed_count} interpretations failed" if failed_count > 0
    end

    results
  end
end
