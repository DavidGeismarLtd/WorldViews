require 'rails_helper'

RSpec.describe PersonasController, type: :controller do
  describe 'GET #index' do
    it 'assigns official active personas ordered by display_order' do
      official_persona1 = create(:persona, :official, display_order: 2, active: true)
      official_persona2 = create(:persona, :official, display_order: 1, active: true)
      custom_persona = create(:persona, :custom, display_order: 0, active: true)
      inactive_persona = create(:persona, :inactive)

      get :index

      expect(assigns(:official_personas)).to eq([ official_persona2, official_persona1 ])
      expect(assigns(:official_personas)).not_to include(inactive_persona)
      expect(assigns(:official_personas)).not_to include(custom_persona)
    end

    it 'assigns empty custom personas when user is not logged in' do
      get :index
      expect(assigns(:custom_personas)).to eq([])
    end

    it 'assigns user custom personas when user is logged in' do
      user = create(:user)
      sign_in user

      user_persona1 = create(:persona, :custom, user: user, display_order: 2, active: true)
      user_persona2 = create(:persona, :custom, user: user, display_order: 1, active: true)
      other_user_persona = create(:persona, :custom, display_order: 0, active: true)

      get :index

      expect(assigns(:custom_personas)).to eq([ user_persona2, user_persona1 ])
      expect(assigns(:custom_personas)).not_to include(other_user_persona)
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
