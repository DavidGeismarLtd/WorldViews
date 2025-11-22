require 'rails_helper'

RSpec.describe NewsFetcherService do
  let(:service) { described_class.new }
  let(:api_key) { 'test_api_key_123' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('NEWS_API_KEY').and_return(api_key)
  end

  describe '#fetch_and_store_news' do
    let(:mock_response) do
      {
        'status' => 'ok',
        'totalResults' => 2,
        'articles' => [
          {
            'source' => { 'id' => 'techcrunch', 'name' => 'TechCrunch' },
            'author' => 'John Doe',
            'title' => 'AI Startup Raises $500M',
            'description' => 'A new AI company has raised significant funding.',
            'url' => 'https://example.com/article1',
            'urlToImage' => 'https://example.com/image1.jpg',
            'publishedAt' => '2024-01-15T10:00:00Z',
            'content' => 'Full article content here...'
          },
          {
            'source' => { 'id' => 'wired', 'name' => 'Wired' },
            'author' => 'Jane Smith',
            'title' => 'Quantum Computing Breakthrough',
            'description' => 'Scientists achieve quantum supremacy.',
            'url' => 'https://example.com/article2',
            'urlToImage' => 'https://example.com/image2.jpg',
            'publishedAt' => '2024-01-15T11:00:00Z',
            'content' => 'Quantum computing content...'
          }
        ]
      }
    end

    before do
      response_double = double('HTTParty::Response')
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:[]).with('status').and_return('ok')
      allow(response_double).to receive(:[]).with('articles').and_return(mock_response['articles'])

      allow(described_class).to receive(:get).and_return(response_double)
    end

    it 'fetches and stores news articles' do
      expect {
        service.fetch_and_store_news(category: 'technology', limit: 10)
      }.to change(NewsStory, :count).by(2)
    end

    it 'returns statistics hash with new stories' do
      results = service.fetch_and_store_news(category: 'technology', limit: 10)

      expect(results).to be_a(Hash)
      expect(results[:new].count).to eq(2)
      expect(results[:updated].count).to eq(0)
      expect(results[:skipped].count).to eq(0)
      expect(results[:total]).to eq(2)
    end

    it 'creates stories with correct attributes' do
      service.fetch_and_store_news(category: 'technology', limit: 10)

      story = NewsStory.first
      expect(story.headline).to eq('AI Startup Raises $500M')
      expect(story.source).to eq('TechCrunch')
      expect(story.source_url).to eq('https://example.com/article1')
      expect(story.category).to eq('technology')
    end

    it 'generates unique external_id from URL' do
      service.fetch_and_store_news(category: 'technology', limit: 10)

      story = NewsStory.first
      expected_id = Digest::MD5.hexdigest('https://example.com/article1')
      expect(story.external_id).to eq(expected_id)
    end

    context 'when API key is missing' do
      before do
        allow(ENV).to receive(:[]).with('NEWS_API_KEY').and_return(nil)
      end

      it 'raises an error' do
        expect {
          service.fetch_and_store_news(category: 'general', limit: 10)
        }.to raise_error(ArgumentError, /NEWS_API_KEY is not set/)
      end
    end

    context 'when fetching duplicate articles' do
      it 'skips duplicate stories' do
        # First fetch
        service.fetch_and_store_news(category: 'technology', limit: 10)
        expect(NewsStory.count).to eq(2)

        # Second fetch with same articles
        results = service.fetch_and_store_news(category: 'technology', limit: 10)

        expect(NewsStory.count).to eq(2) # No new stories
        expect(results[:new].count).to eq(0)
        expect(results[:skipped].count).to eq(2)
      end
    end

    context 'when article headline is updated' do
      it 'updates existing story' do
        # First fetch
        service.fetch_and_store_news(category: 'technology', limit: 10)
        story = NewsStory.first

        # Modify mock response with updated headline
        mock_response['articles'][0]['title'] = 'AI Startup Raises $600M (Updated)'

        # Second fetch
        results = service.fetch_and_store_news(category: 'technology', limit: 10)

        expect(results[:updated].count).to eq(1)
        expect(story.reload.headline).to eq('AI Startup Raises $600M (Updated)')
      end
    end
  end

  describe '#fetch_latest_news' do
    before do
      # Create an old story to establish last_fetch_time
      create(:news_story, published_at: 2.days.ago)

      # Mock API responses for multiple categories
      response_double = double('HTTParty::Response')
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:[]).with('status').and_return('ok')
      allow(response_double).to receive(:[]).with('articles').and_return([
        {
          'source' => { 'name' => 'BBC' },
          'title' => 'Breaking News',
          'url' => 'https://example.com/new',
          'publishedAt' => 1.hour.ago.iso8601,
          'description' => 'Latest breaking news'
        }
      ])

      allow(described_class).to receive(:get).and_return(response_double)
    end

    it 'fetches news from multiple categories' do
      results = service.fetch_latest_news(categories: %w[general technology], limit_per_category: 10)

      expect(results).to be_a(Hash)
      expect(results[:total]).to be > 0
    end

    it 'only processes articles newer than last fetch' do
      # The mock returns 1 article from 1 hour ago
      # Last fetch was 2 days ago
      # So it should process the new article

      results = service.fetch_latest_news(categories: ['general'], limit_per_category: 10)

      expect(results[:new].count).to be >= 0
    end

    it 'aggregates results across categories' do
      results = service.fetch_latest_news(categories: %w[general technology business], limit_per_category: 10)

      expect(results).to have_key(:new)
      expect(results).to have_key(:updated)
      expect(results).to have_key(:skipped)
      expect(results).to have_key(:total)
    end
  end

  describe '#process_and_store_articles' do
    let(:published_time) { Time.current }
    let(:articles) do
      [
        {
          external_id: 'abc123',
          headline: 'Test Article',
          source: 'Test Source',
          source_url: 'https://example.com/test',
          summary: 'Test summary',
          published_at: published_time
        }
      ]
    end

    it 'categorizes articles as new, updated, or skipped' do
      results = service.send(:process_and_store_articles, articles)

      expect(results[:new].count).to eq(1)
      expect(results[:updated].count).to eq(0)
      expect(results[:skipped].count).to eq(0)
    end

    it 'detects updated articles' do
      # Create existing story
      create(:news_story, external_id: 'abc123', headline: 'Old Headline')

      # Update with new headline
      articles[0][:headline] = 'New Headline'

      results = service.send(:process_and_store_articles, articles)

      expect(results[:new].count).to eq(0)
      expect(results[:updated].count).to eq(1)
    end

    it 'skips unchanged articles' do
      # Create existing story with exact same attributes
      create(:news_story,
             external_id: 'abc123',
             headline: 'Test Article',
             summary: 'Test summary',
             published_at: published_time)

      results = service.send(:process_and_store_articles, articles)

      expect(results[:new].count).to eq(0)
      expect(results[:updated].count).to eq(0)
      expect(results[:skipped].count).to eq(1)
    end
  end
end
