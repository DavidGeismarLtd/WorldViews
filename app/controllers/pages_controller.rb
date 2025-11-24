class PagesController < ApplicationController
  def home
    @news_stories = NewsStory.active.recent
    @featured_stories = NewsStory.active.featured.recent.limit(3)
  end
end

