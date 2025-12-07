require 'rails_helper'

RSpec.describe NewsStoriesController, type: :controller do
  include Devise::Test::ControllerHelpers
  describe 'GET #index' do
    let!(:tech_story1) { create(:news_story, category: 'technology', headline: 'AI Breakthrough', published_at: 2.hours.ago) }
    let!(:tech_story2) { create(:news_story, category: 'technology', headline: 'New Gadget Released', published_at: 1.hour.ago) }
    let!(:business_story) { create(:news_story, category: 'business', headline: 'Market Update', published_at: 3.hours.ago) }
    let!(:science_story) { create(:news_story, category: 'science', headline: 'Space Discovery', published_at: 4.hours.ago) }
    let!(:inactive_story) { create(:news_story, category: 'technology', active: false) }

    context 'without filters' do
      it 'returns all active stories' do
        get :index
        expect(assigns(:news_stories).to_a).to match_array([tech_story1, tech_story2, business_story, science_story])
      end

      it 'orders stories by most recent first' do
        get :index
        stories = assigns(:news_stories).to_a
        expect(stories.first).to eq(tech_story2)
        expect(stories.last).to eq(science_story)
      end

      it 'does not include inactive stories' do
        get :index
        expect(assigns(:news_stories)).not_to include(inactive_story)
      end

      it 'assigns categories' do
        get :index
        expect(assigns(:categories)).to eq(%w[general technology business science health sports entertainment])
      end

      it 'assigns personas' do
        persona = create(:persona, official: true, active: true)
        get :index
        expect(assigns(:personas)).to include(persona)
      end
    end

    context 'with category filter' do
      it 'filters stories by category' do
        get :index, params: { category: 'technology' }
        expect(assigns(:news_stories).to_a).to match_array([tech_story1, tech_story2])
      end

      it 'returns empty array for category with no stories' do
        get :index, params: { category: 'sports' }
        expect(assigns(:news_stories).to_a).to be_empty
      end

      it 'assigns the category parameter' do
        get :index, params: { category: 'technology' }
        expect(assigns(:category)).to eq('technology')
      end

      it 'filters business stories correctly' do
        get :index, params: { category: 'business' }
        expect(assigns(:news_stories).to_a).to eq([business_story])
      end

      it 'filters science stories correctly' do
        get :index, params: { category: 'science' }
        expect(assigns(:news_stories).to_a).to eq([science_story])
      end
    end

    context 'with search query' do
      it 'searches stories by headline' do
        get :index, params: { q: 'AI' }
        expect(assigns(:news_stories).to_a).to include(tech_story1)
        expect(assigns(:news_stories).to_a).not_to include(business_story)
      end

      it 'assigns the query parameter' do
        get :index, params: { q: 'AI' }
        expect(assigns(:query)).to eq('AI')
      end
    end

    context 'with both category and search filters' do
      it 'applies both filters' do
        get :index, params: { category: 'technology', q: 'AI' }
        expect(assigns(:news_stories).to_a).to include(tech_story1)
        expect(assigns(:news_stories).to_a).not_to include(tech_story2, business_story)
      end

      it 'returns empty when search does not match category' do
        get :index, params: { category: 'business', q: 'AI' }
        expect(assigns(:news_stories).to_a).to be_empty
      end

      it 'assigns both parameters' do
        get :index, params: { category: 'technology', q: 'AI' }
        expect(assigns(:category)).to eq('technology')
        expect(assigns(:query)).to eq('AI')
      end
    end

    context 'pagination' do
      it 'paginates results' do
        get :index
        expect(assigns(:pagy)).to be_present
      end

      it 'uses pagy for pagination' do
        # Just verify that pagy is being used
        get :index
        expect(assigns(:pagy)).to be_a(Pagy)
        expect(assigns(:news_stories)).to be_present
      end
    end

    context 'turbo frame requests' do
      it 'renders partial for turbo frame requests' do
        request.headers['Turbo-Frame'] = 'news_stories'
        get :index, params: { category: 'technology' }
        expect(response).to render_template(partial: '_news_stories_frame')
      end
    end
  end

  describe 'GET #show' do
    let(:news_story) { create(:news_story) }
    let!(:persona) { create(:persona, official: true, active: true) }

    it 'assigns the news story' do
      get :show, params: { id: news_story.id }
      expect(assigns(:news_story)).to eq(news_story)
    end

    it 'assigns official personas' do
      get :show, params: { id: news_story.id }
      expect(assigns(:official_personas).to_a).to include(persona)
    end

    context 'when story not found' do
      it 'redirects to root path' do
        get :show, params: { id: 'nonexistent' }
        expect(response).to redirect_to(root_path)
      end

      it 'sets an alert message' do
        get :show, params: { id: 'nonexistent' }
        expect(flash[:alert]).to eq('Story not found')
      end
    end
  end
end
