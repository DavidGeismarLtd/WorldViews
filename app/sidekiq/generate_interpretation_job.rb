# Background job to generate a single interpretation for a news story and persona
class GenerateInterpretationJob
  include Sidekiq::Job

  sidekiq_options queue: :interpretations, retry: 2

  def perform(news_story_id, persona_id)
    news_story = NewsStory.find(news_story_id)
    persona = Persona.find(persona_id)

    # Skip if interpretation already exists
    existing = Interpretation.find_by(news_story: news_story, persona: persona)
    if existing
      Rails.logger.info "⏭️  [Sidekiq] Interpretation already exists for #{persona.name} on story #{news_story.id}"
      return
    end

    Rails.logger.info "🎭 [Sidekiq] Generating interpretation: #{persona.name} → #{news_story.headline[0..50]}..."

    # Generate interpretation using the service
    interpretation = InterpretationGeneratorService.new(
      news_story: news_story,
      persona: persona
    ).generate!

    if interpretation
      Rails.logger.info "  ✅ [Sidekiq] Interpretation generated successfully for #{persona.name}"
    else
      Rails.logger.warn "  ⚠️  [Sidekiq] Interpretation generation returned nil for #{persona.name}"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "  ❌ [Sidekiq] Record not found: #{e.message}"
  rescue => e
    Rails.logger.error "  ❌ [Sidekiq] Unexpected error generating interpretation: #{e.message}"
    raise e
  end
end

