require 'rails_helper'

RSpec.describe FetchNewsJob, type: :job do
  let(:service) { instance_double(NewsFetcherService) }

  before do
    allow(NewsFetcherService).to receive(:new).and_return(service)
  end

  describe '#perform' do
    context 'with mode: :latest' do
      let!(:official_persona1) { create(:persona, :official, active: true, display_order: 1) }
      let!(:official_persona2) { create(:persona, :official, active: true, display_order: 2) }
      let!(:custom_persona) { create(:persona, :custom, active: true, display_order: 3) }

      let(:results) do
        {
          new: [create(:news_story), create(:news_story)],
          updated: [create(:news_story)],
          skipped: [create(:news_story)],
          total: 4
        }
      end

      before do
        allow(service).to receive(:fetch_latest_news).and_return(results)
      end

      it 'calls fetch_latest_news on the service with all categories' do
        described_class.new.perform(mode: :latest)

        expect(service).to have_received(:fetch_latest_news).with(
          categories: %w[general technology business science health sports entertainment],
          limit_per_category: 20
        )
      end

      it 'returns statistics hash' do
        result = described_class.new.perform(mode: :latest)

        expect(result).to eq(results)
        expect(result[:new].count).to eq(2)
        expect(result[:updated].count).to eq(1)
        expect(result[:skipped].count).to eq(1)
      end

      it 'generates interpretations synchronously for new stories and official personas only' do
        described_class.new.perform(mode: :latest)

        # Should generate 2 stories × 2 official personas = 4 interpretations
        expect(Interpretation.count).to eq(4)

        # Verify interpretations were created for official personas only
        results[:new].each do |story|
          expect(Interpretation.exists?(news_story: story, persona: official_persona1)).to be true
          expect(Interpretation.exists?(news_story: story, persona: official_persona2)).to be true
          expect(Interpretation.exists?(news_story: story, persona: custom_persona)).to be false
        end
      end

      it 'does not generate interpretations for updated stories' do
        described_class.new.perform(mode: :latest)

        # Should only generate for the 2 new stories, not the 1 updated
        updated_story = results[:updated].first
        expect(Interpretation.where(news_story: updated_story).count).to eq(0)
      end

      it 'accepts custom categories' do
        described_class.new.perform(
          mode: :latest,
          categories: %w[technology science],
          limit_per_category: 30
        )

        expect(service).to have_received(:fetch_latest_news).with(
          categories: %w[technology science],
          limit_per_category: 30
        )
      end
    end

    context 'with mode: :single_category' do
      let(:results) do
        {
          new: [create(:news_story)],
          updated: [],
          skipped: [],
          total: 1
        }
      end

      before do
        allow(service).to receive(:fetch_and_store_news).and_return(results)
      end

      it 'calls fetch_and_store_news on the service' do
        described_class.new.perform(mode: :single_category, categories: ['technology'])

        expect(service).to have_received(:fetch_and_store_news).with(
          category: 'technology',
          limit: 20
        )
      end

      it 'defaults to general category if none provided' do
        described_class.new.perform(mode: :single_category)

        expect(service).to have_received(:fetch_and_store_news).with(
          category: 'general',
          limit: 20
        )
      end
    end

    context 'with invalid mode' do
      it 'raises an error' do
        expect {
          described_class.new.perform(mode: :invalid_mode)
        }.to raise_error(ArgumentError, /Unknown mode/)
      end
    end

    context 'when service raises an error' do
      before do
        allow(service).to receive(:fetch_latest_news).and_raise(StandardError, 'API Error')
      end

      it 'logs the error and re-raises' do
        expect {
          described_class.new.perform(mode: :latest)
        }.to raise_error(StandardError, 'API Error')
      end
    end

    context 'when no new stories are found' do
      let(:results) do
        {
          new: [],
          updated: [],
          skipped: [create(:news_story)],
          total: 1
        }
      end

      before do
        allow(service).to receive(:fetch_latest_news).and_return(results)
      end

      it 'does not generate any interpretations' do
        described_class.new.perform(mode: :latest)

        expect(Interpretation.count).to eq(0)
      end
    end

    context 'when interpretation generation fails' do
      let!(:official_persona) { create(:persona, :official, active: true) }
      let(:results) do
        {
          new: [create(:news_story)],
          updated: [],
          skipped: [],
          total: 1
        }
      end

      before do
        allow(service).to receive(:fetch_latest_news).and_return(results)
        allow(InterpretationGeneratorService).to receive(:new).and_raise(StandardError, 'LLM API Error')
      end

      it 'logs the error and continues without raising' do
        expect {
          described_class.new.perform(mode: :latest)
        }.not_to raise_error

        # Job should complete successfully even if interpretation generation fails
        expect(Interpretation.count).to eq(0)
      end
    end
  end
end
