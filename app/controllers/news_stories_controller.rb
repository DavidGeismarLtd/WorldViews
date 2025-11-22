class NewsStoriesController < ApplicationController
  def index
    @news_stories = NewsStory.active.recent.limit(20)
    @featured_stories = NewsStory.active.featured.recent.limit(3)
  end

  def show
    @news_story = NewsStory.find(params[:id])

    # Official personas (always shown)
    @official_personas = Persona.official.active.ordered

    # User's custom personas (if logged in)
    @custom_personas = if current_user
      Persona.by_user(current_user).active.ordered
    else
      []
    end

    # Combine all personas for display
    @personas = @official_personas + @custom_personas

    # Get or generate interpretations for all personas
    @interpretations = {}
    @personas.each do |persona|
      interpretation = @news_story.interpretation_for(persona)

      # Generate on-demand if not exists
      unless interpretation
        interpretation = generate_interpretation_sync(@news_story, persona)
      end

      @interpretations[persona.id] = interpretation if interpretation
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Story not found"
  end

  private

  def generate_interpretation_sync(news_story, persona)
    # For MVP, generate synchronously (will add async later)
    InterpretationGeneratorService.new(
      news_story: news_story,
      persona: persona
    ).generate!
  end
end
