require 'rails_helper'

RSpec.describe PersonasController, type: :controller do
  describe 'GET #index' do
    it 'assigns all active personas ordered by display_order' do
      persona1 = create(:persona, display_order: 2, active: true)
      persona2 = create(:persona, display_order: 1, active: true)
      inactive_persona = create(:persona, :inactive)

      get :index

      expect(assigns(:personas)).to eq([ persona2, persona1 ])
      expect(assigns(:personas)).not_to include(inactive_persona)
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end

    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    let(:persona) { create(:persona, :revolutionary) }
    let(:news_story1) { create(:news_story) }
    let(:news_story2) { create(:news_story) }

    before do
      create(:interpretation, persona: persona, news_story: news_story1, created_at: 2.days.ago)
      create(:interpretation, persona: persona, news_story: news_story2, created_at: 1.day.ago)
    end

    it 'assigns the requested persona' do
      get :show, params: { slug: persona.slug }
      expect(assigns(:persona)).to eq(persona)
    end

    it 'assigns recent interpretations ordered by most recent first' do
      get :show, params: { slug: persona.slug }
      recent = assigns(:recent_interpretations)
      
      expect(recent.count).to eq(2)
      expect(recent.first.news_story).to eq(news_story2)
      expect(recent.last.news_story).to eq(news_story1)
    end

    it 'limits recent interpretations to 10' do
      11.times { create(:interpretation, persona: persona) }
      
      get :show, params: { slug: persona.slug }
      
      expect(assigns(:recent_interpretations).count).to eq(10)
    end

    it 'renders the show template' do
      get :show, params: { slug: persona.slug }
      expect(response).to render_template(:show)
    end

    it 'returns a successful response' do
      get :show, params: { slug: persona.slug }
      expect(response).to be_successful
    end

    context 'when persona does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          get :show, params: { slug: 'non-existent-slug' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

