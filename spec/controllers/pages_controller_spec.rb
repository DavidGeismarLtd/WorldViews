require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'GET #home' do
    before do
      # Clear existing stories to avoid interference
      NewsStory.destroy_all
    end

    let!(:active_story1) { create(:news_story, active: true, published_at: 2.hours.ago) }
    let!(:active_story2) { create(:news_story, active: true, published_at: 1.hour.ago) }
    let!(:featured_story1) { create(:news_story, active: true, featured: true, published_at: 3.hours.ago) }
    let!(:featured_story2) { create(:news_story, active: true, featured: true, published_at: 4.hours.ago) }
    let!(:inactive_story) { create(:news_story, active: false) }

    it 'returns http success' do
      get :home
      expect(response).to have_http_status(:success)
    end

    it 'assigns all active news stories' do
      get :home
      expect(assigns(:news_stories).to_a).to include(active_story1, active_story2, featured_story1, featured_story2)
    end

    it 'does not include inactive stories' do
      get :home
      expect(assigns(:news_stories)).not_to include(inactive_story)
    end

    it 'orders stories by most recent first' do
      get :home
      stories = assigns(:news_stories).to_a
      expect(stories.first).to eq(active_story2)
    end

    it 'assigns featured stories' do
      get :home
      featured_stories = assigns(:featured_stories).to_a
      expect(featured_stories).to be_present
      expect(featured_stories.all?(&:featured?)).to be true
      expect(featured_stories.all?(&:active?)).to be true
    end

    it 'limits featured stories to 3' do
      # Clear and create exactly 5 featured stories
      NewsStory.destroy_all
      create_list(:news_story, 5, active: true, featured: true)

      get :home
      expect(assigns(:featured_stories).count).to eq(3)
    end

    it 'assigns categories' do
      get :home
      expect(assigns(:categories)).to eq(%w[general technology business science health sports entertainment])
    end

    it 'renders the home template' do
      get :home
      expect(response).to render_template(:home)
    end
  end
end
