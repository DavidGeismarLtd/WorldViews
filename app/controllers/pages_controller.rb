class PagesController < ApplicationController
  # All available NewsAPI categories
  CATEGORIES = %w[general technology business science health sports entertainment].freeze

  def home
    @news_stories = NewsStory.active.recent
    @featured_stories = NewsStory.active.featured.recent.limit(3)
    @categories = CATEGORIES
  end
end
