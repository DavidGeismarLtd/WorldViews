require 'rails_helper'

RSpec.describe Persona, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should have_many(:interpretations).dependent(:destroy) }
    it { should have_many(:news_stories).through(:interpretations) }
  end

  describe 'validations' do
    subject { create(:persona) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:system_prompt) }
    it { should validate_uniqueness_of(:slug) }

    context 'slug validation' do
      it 'validates presence of slug when name is blank' do
        persona = build(:persona, name: nil, slug: nil)
        expect(persona).not_to be_valid
        expect(persona.errors[:slug]).to include("can't be blank")
      end
    end
  end

  describe 'callbacks' do
    context 'when creating a persona without a slug' do
      it 'generates a slug from the name' do
        persona = create(:persona, name: "The Test Persona", slug: nil)
        expect(persona.slug).to eq("the-test-persona")
      end
    end

    context 'when creating a persona with a slug' do
      it 'does not override the provided slug' do
        persona = create(:persona, name: "The Test Persona", slug: "custom-slug")
        expect(persona.slug).to eq("custom-slug")
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active personas' do
        active_persona = create(:persona, active: true)
        inactive_persona = create(:persona, :inactive)

        expect(Persona.active).to include(active_persona)
        expect(Persona.active).not_to include(inactive_persona)
      end
    end

    describe '.ordered' do
      it 'orders personas by display_order and created_at' do
        persona3 = create(:persona, display_order: 3)
        persona1 = create(:persona, display_order: 1)
        persona2 = create(:persona, display_order: 2)

        expect(Persona.ordered).to eq([persona1, persona2, persona3])
      end
    end
  end

  describe '#recent_interpretations' do
    let(:persona) { create(:persona) }
    let(:news_story1) { create(:news_story) }
    let(:news_story2) { create(:news_story) }
    let(:news_story3) { create(:news_story) }

    before do
      create(:interpretation, persona: persona, news_story: news_story1, created_at: 3.days.ago)
      create(:interpretation, persona: persona, news_story: news_story2, created_at: 1.day.ago)
      create(:interpretation, persona: persona, news_story: news_story3, created_at: 2.days.ago)
    end

    it 'returns interpretations ordered by most recent first' do
      recent = persona.recent_interpretations(3)
      expect(recent.map(&:news_story)).to eq([news_story2, news_story3, news_story1])
    end

    it 'limits the number of interpretations returned' do
      expect(persona.recent_interpretations(2).count).to eq(2)
    end

    it 'defaults to 10 interpretations' do
      11.times { create(:interpretation, persona: persona) }
      expect(persona.recent_interpretations.count).to eq(10)
    end
  end

  describe '#total_interpretations' do
    let(:persona) { create(:persona) }

    it 'returns the total count of interpretations' do
      create_list(:interpretation, 5, persona: persona)
      expect(persona.total_interpretations).to eq(5)
    end

    it 'returns 0 when there are no interpretations' do
      expect(persona.total_interpretations).to eq(0)
    end
  end

  describe '#average_interpretation_length' do
    let(:persona) { create(:persona) }

    it 'returns the average length of interpretation content' do
      create(:interpretation, persona: persona, content: "a" * 100)
      create(:interpretation, persona: persona, content: "b" * 200)

      expect(persona.average_interpretation_length).to eq(150)
    end

    it 'returns 0 when there are no interpretations' do
      expect(persona.average_interpretation_length).to eq(0)
    end
  end

  describe '#most_common_category' do
    let(:persona) { create(:persona) }

    it 'returns the most common news category' do
      tech_story1 = create(:news_story, category: 'technology')
      tech_story2 = create(:news_story, category: 'technology')
      business_story = create(:news_story, category: 'business')

      create(:interpretation, persona: persona, news_story: tech_story1)
      create(:interpretation, persona: persona, news_story: tech_story2)
      create(:interpretation, persona: persona, news_story: business_story)

      expect(persona.most_common_category).to eq('technology')
    end

    it 'returns nil when there are no interpretations' do
      expect(persona.most_common_category).to be_nil
    end
  end

  describe '#generate_interpretation_for' do
    let(:persona) { create(:persona) }
    let(:news_story) { create(:news_story) }

    it 'calls InterpretationGeneratorService' do
      service_double = instance_double(InterpretationGeneratorService)
      allow(InterpretationGeneratorService).to receive(:new).and_return(service_double)
      allow(service_double).to receive(:generate!)

      persona.generate_interpretation_for(news_story)

      expect(InterpretationGeneratorService).to have_received(:new).with(
        news_story: news_story,
        persona: persona
      )
      expect(service_double).to have_received(:generate!)
    end
  end

  describe 'scopes' do
    let!(:official_persona) { create(:persona, official: true, visibility: "public") }
    let!(:custom_persona) { create(:persona, official: false, visibility: "public") }
    let!(:private_persona) { create(:persona, official: false, visibility: "private") }
    let(:user) { create(:user) }

    describe '.official' do
      it 'returns only official personas' do
        expect(Persona.official).to include(official_persona)
        expect(Persona.official).not_to include(custom_persona)
      end
    end

    describe '.custom' do
      it 'returns only custom personas' do
        expect(Persona.custom).to include(custom_persona)
        expect(Persona.custom).not_to include(official_persona)
      end
    end

    describe '.public_personas' do
      it 'returns only public personas' do
        expect(Persona.public_personas).to include(official_persona, custom_persona)
        expect(Persona.public_personas).not_to include(private_persona)
      end
    end

    describe '.by_user' do
      it 'returns personas created by a specific user' do
        user_persona = create(:persona, user: user)
        expect(Persona.by_user(user)).to include(user_persona)
        expect(Persona.by_user(user)).not_to include(custom_persona)
      end
    end
  end

  describe '#viewable_by?' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    context 'when persona is official' do
      let(:persona) { create(:persona, official: true) }

      it 'is viewable by anyone' do
        expect(persona.viewable_by?(nil)).to be true
        expect(persona.viewable_by?(user)).to be true
      end
    end

    context 'when persona is public' do
      let(:persona) { create(:persona, official: false, visibility: "public", user: user) }

      it 'is viewable by anyone' do
        expect(persona.viewable_by?(nil)).to be true
        expect(persona.viewable_by?(other_user)).to be true
      end
    end

    context 'when persona is private' do
      let(:persona) { create(:persona, official: false, visibility: "private", user: user) }

      it 'is not viewable by guests' do
        expect(persona.viewable_by?(nil)).to be false
      end

      it 'is not viewable by other users' do
        expect(persona.viewable_by?(other_user)).to be false
      end

      it 'is viewable by the owner' do
        expect(persona.viewable_by?(user)).to be true
      end
    end

    context 'when persona is unlisted' do
      let(:persona) { create(:persona, official: false, visibility: "unlisted", user: user) }

      it 'is viewable by anyone with the link' do
        expect(persona.viewable_by?(nil)).to be true
        expect(persona.viewable_by?(other_user)).to be true
      end
    end
  end

  describe '#editable_by?' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    context 'when persona is official' do
      let(:persona) { create(:persona, official: true) }

      it 'is not editable by anyone' do
        expect(persona.editable_by?(user)).to be false
        expect(persona.editable_by?(nil)).to be false
      end
    end

    context 'when persona is custom' do
      let(:persona) { create(:persona, official: false, user: user) }

      it 'is not editable by guests' do
        expect(persona.editable_by?(nil)).to be false
      end

      it 'is not editable by other users' do
        expect(persona.editable_by?(other_user)).to be false
      end

      it 'is editable by the owner' do
        expect(persona.editable_by?(user)).to be true
      end
    end
  end
end
