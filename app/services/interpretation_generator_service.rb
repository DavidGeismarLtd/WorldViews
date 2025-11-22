# Service to generate persona interpretations for news stories
class InterpretationGeneratorService
  def initialize(news_story:, persona:)
    @news_story = news_story
    @persona = persona
    @llm_client = LlmClientService.new
  end

  def generate!
    # Check if interpretation already exists
    existing = Interpretation.find_by(news_story: @news_story, persona: @persona)
    return existing if existing

    Rails.logger.info "🎭 Generating interpretation: #{@persona.name} → #{@news_story.headline[0..50]}..."

    # Check cache first for quick take
    cache_key = "interpretation/#{@news_story.id}/#{@persona.id}/v1"
    cached_result = Rails.cache.read(cache_key)

    if cached_result
      Rails.logger.info "  ✓ Found in cache"
      return create_interpretation_from_cache(cached_result)
    end

    # Generate quick take (using headline + summary)
    quick_result = @llm_client.generate_interpretation(
      news_summary: build_news_summary,
      persona_prompt: @persona.system_prompt
    )

    # Cache the quick take
    Rails.cache.write(cache_key, quick_result, expires_in: 30.days)

    # Create interpretation record
    interpretation = Interpretation.create!(
      news_story: @news_story,
      persona: @persona,
      content: quick_result[:content],
      llm_model: quick_result[:model],
      llm_tokens_used: quick_result[:tokens_used],
      generation_time_ms: quick_result[:generation_time_ms],
      cached: false,
      metadata: {
        provider: quick_result[:provider],
        generated_at: Time.current
      }
    )

    Rails.logger.info "  ✅ Generated quick take (#{quick_result[:tokens_used]} tokens, #{quick_result[:generation_time_ms]}ms)"
    interpretation
  end

  def generate_detailed!
    interpretation = Interpretation.find_by(news_story: @news_story, persona: @persona)

    # Return if detailed content already exists
    return interpretation if interpretation&.detailed_content.present?

    # Create basic interpretation if it doesn't exist
    interpretation ||= generate!

    Rails.logger.info "📝 Generating detailed interpretation: #{@persona.name} → #{@news_story.headline[0..50]}..."

    # Check cache for detailed interpretation (v2 = HTML structured format)
    detailed_cache_key = "interpretation/#{@news_story.id}/#{@persona.id}/detailed/v2"
    cached_detailed = Rails.cache.read(detailed_cache_key)

    if cached_detailed
      Rails.logger.info "  ✓ Found detailed in cache"
      interpretation.update!(detailed_content: cached_detailed[:content])
      return interpretation
    end

    # Fetch full article content
    full_content = @news_story.fetch_full_content

    # Generate detailed content
    detailed_result = generate_detailed_content(full_content)

    # Cache the detailed result
    Rails.cache.write(detailed_cache_key, detailed_result, expires_in: 30.days)

    # Update interpretation with detailed content
    interpretation.update!(detailed_content: detailed_result[:content])

    Rails.logger.info "  ✅ Generated detailed analysis (#{detailed_result[:tokens_used]} tokens)"
    interpretation
  end

  private

  def generate_detailed_content(full_content)
    # Generate detailed interpretation using full article
    @llm_client.generate_interpretation(
      news_summary: build_detailed_summary(full_content),
      persona_prompt: build_detailed_prompt
    )
  end

  def build_news_summary
    # Combine headline and summary for context (quick take)
    summary = @news_story.headline.dup
    summary += ". #{@news_story.summary}" if @news_story.summary.present?
    summary
  end

  def build_detailed_summary(full_content)
    # Build comprehensive summary for detailed analysis
    summary = "HEADLINE: #{@news_story.headline}\n\n"
    summary += "SOURCE: #{@news_story.source}\n\n"
    summary += "FULL ARTICLE:\n#{full_content}"
    summary
  end

  def build_detailed_prompt
    # Enhanced prompt for detailed analysis with HTML structure
    <<~PROMPT
      #{@persona.system_prompt}

      Provide a comprehensive, detailed analysis of this article. Go deeper than a quick take - analyze the implications, context, and what this means from your worldview.

      Format your response as HTML using these tags only: <h3>, <h4>, <p>, <ul>, <li>, <strong>, <em>, <blockquote>

      Structure your analysis like this:
      - Start with an <h3> heading that captures your main reaction
      - Use <h4> subheadings to organize different aspects of your analysis (e.g., "The Real Story", "What They're Not Telling You", "Why This Matters")
      - Write 4-6 paragraphs using <p> tags
      - Use <ul> and <li> for key points or lists where appropriate
      - Use <strong> for emphasis and <em> for subtle points
      - Use <blockquote> if you want to highlight a particularly important insight

      Make it engaging, opinionated, and true to your character. This is your deep dive - show your full perspective!
    PROMPT
  end

  def create_interpretation_from_cache(cached_result)
    Interpretation.create!(
      news_story: @news_story,
      persona: @persona,
      content: cached_result[:content],
      llm_model: cached_result[:model],
      llm_tokens_used: cached_result[:tokens_used],
      generation_time_ms: cached_result[:generation_time_ms],
      cached: true,
      metadata: {
        provider: cached_result[:provider],
        cached_at: Time.current
      }
    )
  end
end
