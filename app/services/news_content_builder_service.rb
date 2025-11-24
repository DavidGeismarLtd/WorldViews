# Service to format news content for LLM consumption
# Responsible for: Preparing news story data in the right format for different interpretation types
class NewsContentBuilderService
  def initialize(news_story:)
    @news_story = news_story
  end

  # Build content for quick take (uses full content if available, otherwise headline + summary)
  def for_quick_take
    @news_story.content_for_interpretation
  end

  # Build content for detailed analysis (structured with labels for better LLM comprehension)
  def for_detailed_analysis(full_content)
    <<~CONTENT
      HEADLINE: #{@news_story.headline}

      SOURCE: #{@news_story.source}

      FULL ARTICLE:
      #{full_content}
    CONTENT
  end
end

