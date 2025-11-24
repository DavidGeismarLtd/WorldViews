require 'rails_helper'

RSpec.describe NewsContentBuilderService do
  let(:news_story) do
    create(:news_story,
      headline: "Tech Giant Announces Layoffs",
      summary: "Major technology company cuts 10,000 jobs amid economic uncertainty.",
      full_content: "Full article content with detailed information about the layoffs and company strategy."
    )
  end
  let(:service) { described_class.new(news_story: news_story) }

  describe '#for_quick_take' do
    subject(:content) { service.for_quick_take }

    it 'delegates to news_story.content_for_interpretation' do
      expect(news_story).to receive(:content_for_interpretation)
      service.for_quick_take
    end

    it 'returns the content for interpretation' do
      expect(content).to eq(news_story.content_for_interpretation)
    end

    it 'returns a string' do
      expect(content).to be_a(String)
    end

    it 'is not empty' do
      expect(content).not_to be_empty
    end
  end

  describe '#for_detailed_analysis' do
    let(:full_content) { "This is the full article content with all details about the layoffs." }
    subject(:content) { service.for_detailed_analysis(full_content) }

    it 'includes the headline with label' do
      expect(content).to include("HEADLINE: #{news_story.headline}")
    end

    it 'includes the source with label' do
      expect(content).to include("SOURCE: #{news_story.source}")
    end

    it 'includes the full article content with label' do
      expect(content).to include("FULL ARTICLE:")
      expect(content).to include(full_content)
    end

    it 'returns a string' do
      expect(content).to be_a(String)
    end

    it 'is not empty' do
      expect(content).not_to be_empty
    end

    it 'structures content with proper labels' do
      expect(content).to match(/HEADLINE:.*SOURCE:.*FULL ARTICLE:/m)
    end

    context 'with different full content' do
      let(:different_content) { "Different article content about company restructuring." }

      it 'uses the provided full content' do
        result = service.for_detailed_analysis(different_content)
        expect(result).to include(different_content)
        expect(result).not_to include(full_content)
      end
    end
  end

  describe 'integration with different news stories' do
    let(:another_story) do
      create(:news_story,
        headline: "Climate Summit Reaches Agreement",
        summary: "World leaders agree on new climate targets.",
        source: "BBC News"
      )
    end
    let(:another_service) { described_class.new(news_story: another_story) }

    it 'builds different content for different stories' do
      content1 = service.for_detailed_analysis("Content 1")
      content2 = another_service.for_detailed_analysis("Content 2")

      expect(content1).to include(news_story.headline)
      expect(content2).to include(another_story.headline)
      expect(content1).not_to eq(content2)
    end
  end
end

