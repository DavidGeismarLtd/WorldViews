# Background job to generate persona avatars using DALL-E
class GeneratePersonaAvatarJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 2

  def perform(persona_id)
    persona = Persona.find(persona_id)

    # Skip if avatar already exists
    if persona.avatar_url.present?
      Rails.logger.info "⏭️  [Sidekiq] Persona #{persona.name} already has an avatar, skipping generation"
      return
    end

    Rails.logger.info "🎨 [Sidekiq] Generating avatar for persona: #{persona.name}..."

    # Generate avatar using the service
    service = AvatarGeneratorService.new(persona)
    avatar_url = service.generate!

    if avatar_url
      Rails.logger.info "  ✅ [Sidekiq] Avatar generated successfully for #{persona.name}"
    else
      Rails.logger.warn "  ⚠️  [Sidekiq] Avatar generation returned nil for #{persona.name}"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "  ❌ [Sidekiq] Persona not found: #{e.message}"
  rescue AvatarGeneratorService::AvatarGenerationError => e
    Rails.logger.error "  ❌ [Sidekiq] Avatar generation failed for persona #{persona_id}: #{e.message}"
    # Don't retry on generation errors
    raise e unless e.message.include?("No OPENAI_API_KEY")
  rescue => e
    Rails.logger.error "  ❌ [Sidekiq] Unexpected error generating avatar for persona #{persona_id}: #{e.message}"
    raise e
  end
end

