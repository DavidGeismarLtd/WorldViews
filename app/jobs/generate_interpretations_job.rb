# Background job to generate interpretations for a news story
class GenerateInterpretationsJob < ApplicationJob
  queue_as :default

  # Generate interpretations for all active personas
  def perform(news_story_id, persona_id = nil)
    news_story = NewsStory.find(news_story_id)

    if persona_id
      # Generate for specific persona
      persona = Persona.find(persona_id)
      generate_for_persona(news_story, persona)
    else
      # Generate for all active personas
      Persona.active.ordered.each do |persona|
        generate_for_persona(news_story, persona)
      end
    end
  end

  private

  def generate_for_persona(news_story, persona)
    # Skip if interpretation already exists
    return if Interpretation.exists?(news_story: news_story, persona: persona)

    InterpretationGeneratorService.new(
      news_story: news_story,
      persona: persona
    ).generate!
  end
end
