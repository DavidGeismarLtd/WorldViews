class NewsStoriesController < ApplicationController
  # All available NewsAPI categories
  CATEGORIES = %w[general technology business science health sports entertainment].freeze

  def index
    @query = params[:q]
    @category = params[:category]

    # Build the query
    stories = NewsStory.active
    stories = stories.by_category(@category) if @category.present?
    stories = stories.search(@query)

    @pagy, @news_stories = pagy(stories.recent, items: 5)
    @featured_stories = NewsStory.active.featured.recent.limit(3)
    @personas = Persona.official.active.ordered
    @categories = CATEGORIES

    respond_to do |format|
      format.html do
        # For Turbo Frame requests (search), only render the frame
        if turbo_frame_request_id == "news_stories"
          render partial: "news_stories_frame", locals: { news_stories: @news_stories, pagy: @pagy, query: @query, category: @category }
        end
      end
      format.turbo_stream
    end
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

    # Combine all personas for display (custom first, then official)
    @personas = @custom_personas + @official_personas

    # Get or generate interpretations for all personas
    @interpretations = {}
    @personas.each do |persona|
      interpretation = @news_story.interpretation_for(persona)

      # Generate in background if not exists (async)
      unless interpretation
        generate_interpretation_async(@news_story, persona)
      end

      @interpretations[persona.id] = interpretation if interpretation
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Story not found"
  end

  private

  def generate_interpretation_async(news_story, persona)
    # Generate interpretation in background job
    GenerateInterpretationJob.perform_async(news_story.id, persona.id)
  end
end
