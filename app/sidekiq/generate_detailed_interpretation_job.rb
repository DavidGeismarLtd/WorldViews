class GenerateDetailedInterpretationJob
  include Sidekiq::Job

  sidekiq_options queue: :interpretations, retry: 3

  def perform(interpretation_id)
    interpretation = Interpretation.find(interpretation_id)

    # Skip if detailed content already exists
    return if interpretation.detailed_content.present?

    Rails.logger.info "📝 [Sidekiq] Generating detailed interpretation: #{interpretation.persona.name} → #{interpretation.news_story.headline[0..50]}..."

    # Generate detailed interpretation using the service
    service = InterpretationGeneratorService.new(
      news_story: interpretation.news_story,
      persona: interpretation.persona
    )

    # This will update the existing interpretation with detailed content
    # and trigger the after_commit callback to broadcast the update
    service.generate_detailed!

    Rails.logger.info "  ✅ [Sidekiq] Detailed interpretation generated successfully for #{interpretation.persona.name}"
  end
end
