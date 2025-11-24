# == Schema Information
#
# Table name: news_stories
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(TRUE), not null
#  category     :string
#  featured     :boolean          default(FALSE), not null
#  full_content :text
#  headline     :string           not null
#  image_url    :string
#  metadata     :jsonb
#  published_at :datetime
#  source       :string           not null
#  source_url   :string
#  summary      :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string           not null
#
# Indexes
#
#  index_news_stories_on_category             (category)
#  index_news_stories_on_created_at           (created_at)
#  index_news_stories_on_external_id          (external_id) UNIQUE
#  index_news_stories_on_featured_and_active  (featured,active)
#  index_news_stories_on_published_at         (published_at)
#
require 'rails_helper'

RSpec.describe NewsStory, type: :model do
  describe 'associations' do
    it { should have_many(:interpretations).dependent(:destroy) }
    it { should have_many(:personas).through(:interpretations) }
  end

  describe 'validations' do
    it { should validate_presence_of(:external_id) }
    it { should validate_presence_of(:headline) }
    it { should validate_presence_of(:source) }

    it 'validates uniqueness of external_id' do
      create(:news_story, external_id: 'unique123')
      duplicate = build(:news_story, external_id: 'unique123')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_id]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    # Disable auto-featuring callback for these tests
    before do
      allow_any_instance_of(NewsStory).to receive(:update_featured_stories)
    end

    let!(:active_story) { create(:news_story, active: true) }
    let!(:inactive_story) { create(:news_story, active: false) }
    let!(:featured_story) { create(:news_story, featured: true) }
    let!(:tech_story) { create(:news_story, category: 'technology') }
    let!(:old_story) { create(:news_story, published_at: 5.days.ago) }
    let!(:new_story) { create(:news_story, published_at: 1.hour.ago) }

    describe '.active' do
      it 'returns only active stories' do
        expect(NewsStory.active).to include(active_story)
        expect(NewsStory.active).not_to include(inactive_story)
      end
    end

    describe '.featured' do
      it 'returns only featured stories' do
        expect(NewsStory.featured).to include(featured_story)
        expect(NewsStory.featured).not_to include(active_story)
      end
    end

    describe '.recent' do
      it 'orders stories by published_at descending' do
        recent_stories = NewsStory.recent
        # First story should be the newest
        expect(recent_stories.first.published_at).to be >= recent_stories.last.published_at
      end
    end

    describe '.by_category' do
      it 'filters stories by category' do
        expect(NewsStory.by_category('technology')).to include(tech_story)
        expect(NewsStory.by_category('technology')).not_to include(active_story)
      end
    end

    describe '.search' do
      let!(:story1) { create(:news_story, headline: 'Breaking: AI Revolution in Healthcare', source: 'TechNews', category: 'technology') }
      let!(:story2) { create(:news_story, headline: 'Stock Market Update', source: 'Bloomberg', category: 'business') }
      let!(:story3) { create(:news_story, headline: 'New AI Regulations Announced', summary: 'Government announces new AI policies', source: 'Reuters', category: 'politics') }

      it 'returns all stories when query is blank' do
        results = NewsStory.search('')
        expect(results.count).to be >= 3
      end

      it 'returns all stories when query is nil' do
        results = NewsStory.search(nil)
        expect(results.count).to be >= 3
      end

      it 'searches by headline' do
        results = NewsStory.search('AI Revolution')
        expect(results).to include(story1)
        expect(results).not_to include(story2)
      end

      it 'searches by source' do
        results = NewsStory.search('Bloomberg')
        expect(results).to include(story2)
        expect(results).not_to include(story1)
      end

      it 'searches by category' do
        results = NewsStory.search('technology')
        expect(results).to include(story1)
        expect(results).not_to include(story2)
      end

      it 'searches by summary' do
        results = NewsStory.search('Government announces')
        expect(results).to include(story3)
        expect(results).not_to include(story1)
      end

      it 'is case insensitive' do
        results = NewsStory.search('ai revolution')
        expect(results).to include(story1)
      end

      it 'finds partial matches' do
        results = NewsStory.search('AI')
        expect(results).to include(story1, story3)
        expect(results).not_to include(story2)
      end

      it 'handles special SQL characters safely' do
        expect {
          NewsStory.search("'; DROP TABLE news_stories; --")
        }.not_to raise_error
      end
    end
  end

  describe '.latest' do
    it 'returns active recent stories limited to specified count' do
      create_list(:news_story, 15, active: true)
      create(:news_story, active: false)

      latest = NewsStory.latest(10)

      expect(latest.count).to eq(10)
      expect(latest.all?(&:active)).to be true
    end
  end

  describe '.last_fetch_time' do
    context 'when stories exist' do
      it 'returns the most recent published_at timestamp' do
        create(:news_story, published_at: 2.days.ago)
        most_recent = create(:news_story, published_at: 1.hour.ago)

        expect(NewsStory.last_fetch_time).to eq(most_recent.published_at)
      end
    end

    context 'when no stories exist' do
      it 'returns 7 days ago' do
        expect(NewsStory.last_fetch_time).to be_within(1.second).of(7.days.ago)
      end
    end
  end

  describe '.needs_sync?' do
    context 'when last story is older than 6 hours' do
      it 'returns true' do
        create(:news_story, published_at: 7.hours.ago)

        expect(NewsStory.needs_sync?).to be true
      end
    end

    context 'when last story is newer than 6 hours' do
      it 'returns false' do
        create(:news_story, published_at: 1.hour.ago)

        expect(NewsStory.needs_sync?).to be false
      end
    end

    context 'when no stories exist' do
      it 'returns true' do
        expect(NewsStory.needs_sync?).to be true
      end
    end
  end

  describe 'featured stories auto-marking' do
    context 'when creating new stories' do
      it 'marks the 3 newest stories as featured' do
        # Create 5 stories with different published_at times
        story1 = create(:news_story, published_at: 5.hours.ago)
        story2 = create(:news_story, published_at: 4.hours.ago)
        story3 = create(:news_story, published_at: 3.hours.ago)
        story4 = create(:news_story, published_at: 2.hours.ago)
        story5 = create(:news_story, published_at: 1.hour.ago)

        # The 3 most recent should be featured
        expect(NewsStory.featured.count).to eq(3)
        expect(NewsStory.featured.pluck(:id)).to match_array([ story3.id, story4.id, story5.id ])
      end

      it 'removes featured flag from older stories when new ones arrive' do
        # Create 3 old stories
        old1 = create(:news_story, published_at: 5.days.ago)
        old2 = create(:news_story, published_at: 4.days.ago)
        old3 = create(:news_story, published_at: 3.days.ago)

        # They should be featured (top 3)
        expect(NewsStory.featured.pluck(:id)).to match_array([ old1.id, old2.id, old3.id ])

        # Create 3 new stories
        new1 = create(:news_story, published_at: 3.hours.ago)
        new2 = create(:news_story, published_at: 2.hours.ago)
        new3 = create(:news_story, published_at: 1.hour.ago)

        # Now only new stories should be featured
        expect(NewsStory.featured.count).to eq(3)
        expect(NewsStory.featured.pluck(:id)).to match_array([ new1.id, new2.id, new3.id ])

        # Old stories should no longer be featured
        expect(old1.reload.featured).to be false
        expect(old2.reload.featured).to be false
        expect(old3.reload.featured).to be false
      end

      it 'handles inactive stories correctly' do
        # Create 2 active and 2 inactive stories
        active1 = create(:news_story, active: true, published_at: 4.hours.ago)
        inactive1 = create(:news_story, active: false, published_at: 3.hours.ago)
        active2 = create(:news_story, active: true, published_at: 2.hours.ago)
        active3 = create(:news_story, active: true, published_at: 1.hour.ago)

        # Only active stories should be featured
        expect(NewsStory.featured.count).to eq(3)
        expect(NewsStory.featured.pluck(:id)).to match_array([ active1.id, active2.id, active3.id ])
        expect(inactive1.reload.featured).to be false
      end
    end
  end

  describe '#display_image_url' do
    context 'when image_url is present' do
      it 'returns the actual image_url' do
        story = create(:news_story, image_url: 'https://example.com/image.jpg')
        expect(story.display_image_url).to eq('https://example.com/image.jpg')
      end
    end

    context 'when image_url is blank' do
      it 'returns the default image url' do
        story = create(:news_story, image_url: nil, category: 'technology')
        expect(story.display_image_url).to eq(story.default_image_url)
      end
    end

    context 'when image_url is empty string' do
      it 'returns the default image url' do
        story = create(:news_story, image_url: '', category: 'politics')
        expect(story.display_image_url).to eq(story.default_image_url)
      end
    end
  end

  describe '#default_image_url' do
    context 'when category is present' do
      it 'generates a placeholder with the category name' do
        story = create(:news_story, category: 'technology')
        expect(story.default_image_url).to include('Technology')
        expect(story.default_image_url).to include('placehold.co')
      end
    end

    context 'when category is blank' do
      it 'generates a placeholder with "news" as default' do
        story = create(:news_story, category: nil)
        expect(story.default_image_url).to include('News')
        expect(story.default_image_url).to include('placehold.co')
      end
    end
  end
end
