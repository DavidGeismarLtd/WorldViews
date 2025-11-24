# Service to orchestrate persona interpretation generation for news stories
# Responsible for: Workflow coordination, caching, and database persistence
class InterpretationGeneratorService
  def initialize(news_story:, persona:)
    @news_story = news_story
    @persona = persona
    @llm_client = LlmClientService.new
    @prompt_builder = PromptBuilderService.new(persona: @persona)
    @content_builder = NewsContentBuilderService.new(news_story: @news_story)
  end

  def generate!
    # Check if interpretation already exists
    existing = Interpretation.find_by(news_story: @news_story, persona: @persona)
    return existing if existing

    Rails.logger.info "🎭 Generating interpretation: #{@persona.name} → #{@news_story.headline[0..50]}..."

    # Check cache first for quick take (v3 = refactored architecture)
    cache_key = build_cache_key(:quick)
    cached_result = Rails.cache.read(cache_key)

    if cached_result
      Rails.logger.info "  ✓ Found in cache"
      return create_interpretation(cached_result, cached: true)
    end

    # Generate quick take using LLM
    result = @llm_client.chat(
      system_prompt: @prompt_builder.build_quick_take_prompt,
      user_message: @prompt_builder.build_user_message(@content_builder.for_quick_take)
    )

    # Cache the result
    Rails.cache.write(cache_key, result, expires_in: 30.days)

    # Create and return interpretation record
    interpretation = create_interpretation(result, cached: false)

    Rails.logger.info "  ✅ Generated quick take (#{result[:tokens_used]} tokens, #{result[:generation_time_ms]}ms)"
    interpretation
  end

  def generate_detailed!
    interpretation = Interpretation.find_by(news_story: @news_story, persona: @persona)

    # Return if detailed content already exists
    return interpretation if interpretation&.detailed_content.present?

    # Create basic interpretation if it doesn't exist
    interpretation ||= generate!

    Rails.logger.info "📝 Generating detailed interpretation: #{@persona.name} → #{@news_story.headline[0..50]}..."

    # Check cache for detailed interpretation (v3 = refactored architecture)
    cache_key = build_cache_key(:detailed)
    cached_result = Rails.cache.read(cache_key)

    if cached_result
      Rails.logger.info "  ✓ Found detailed in cache"
      interpretation.update!(detailed_content: cached_result[:content])
      return interpretation
    end

    # Fetch full article content
    full_content = @news_story.fetch_full_content

    # Generate detailed analysis using LLM
    result = @llm_client.chat(
      system_prompt: @prompt_builder.build_detailed_analysis_prompt,
      user_message: @prompt_builder.build_user_message(
        @content_builder.for_detailed_analysis(full_content)
      )
    )

    # Cache the result
    Rails.cache.write(cache_key, result, expires_in: 30.days)

    # Update interpretation with detailed content
    interpretation.update!(detailed_content: result[:content])

    Rails.logger.info "  ✅ Generated detailed analysis (#{result[:tokens_used]} tokens)"
    interpretation
  end

  private

  def build_cache_key(type)
    "interpretation/#{@news_story.id}/#{@persona.id}/#{type}/v3"
  end

  def create_interpretation(result, cached:)
    Interpretation.create!(
      news_story: @news_story,
      persona: @persona,
      content: result[:content],
      llm_model: result[:model],
      llm_tokens_used: result[:tokens_used],
      generation_time_ms: result[:generation_time_ms],
      cached: cached,
      metadata: {
        provider: result[:provider],
        generated_at: Time.current,
        cached_at: cached ? Time.current : nil
      }
    )
  end
end
