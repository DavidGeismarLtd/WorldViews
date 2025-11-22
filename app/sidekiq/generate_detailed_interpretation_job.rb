class GenerateDetailedInterpretationJob
  include Sidekiq::Job

  sidekiq_options queue: :interpretations, retry: 3

  def perform(interpretation_id)
    interpretation = Interpretation.find(interpretation_id)

    # Skip if detailed content already exists
    return if interpretation.detailed_content.present?

    Rails.logger.info "📝 [Sidekiq] Generating detailed interpretation: #{interpretation.persona.name} → #{interpretation.news_story.headline[0..50]}..."

    # Generate detailed interpretation
    service = InterpretationGeneratorService.new(
      news_story: interpretation.news_story,
      persona: interpretation.persona
    )

    # Fetch full article content
    full_content = interpretation.news_story.fetch_full_content

    # Check cache for detailed interpretation (v2 = HTML structured format)
    detailed_cache_key = "interpretation/#{interpretation.news_story_id}/#{interpretation.persona_id}/detailed/v2"
    cached_detailed = Rails.cache.read(detailed_cache_key)

    if cached_detailed
      Rails.logger.info "  ✓ Found detailed in cache"
      interpretation.update!(detailed_content: cached_detailed[:content])
      return
    end

    # Generate detailed interpretation using full article
    detailed_result = service.send(:generate_detailed_content, full_content)

    # Cache the detailed result
    Rails.cache.write(detailed_cache_key, detailed_result, expires_in: 30.days)

    # Update interpretation with detailed content (this will trigger after_commit callback)
    interpretation.update!(detailed_content: detailed_result[:content])

    Rails.logger.info "  ✅ Generated detailed analysis (#{detailed_result[:tokens_used]} tokens)"
  end
end
