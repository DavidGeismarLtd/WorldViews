require 'rails_helper'

RSpec.describe FetchNewsJob, type: :job do
  let(:service) { instance_double(NewsFetcherService) }

  before do
    allow(NewsFetcherService).to receive(:new).and_return(service)
  end

  describe '#perform' do
    context 'with mode: :latest' do
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

      it 'calls fetch_latest_news on the service' do
        described_class.new.perform(mode: :latest)

        expect(service).to have_received(:fetch_latest_news).with(
          categories: %w[general technology business],
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

      it 'queues interpretation jobs for new stories only' do
        allow(GenerateInterpretationsJob).to receive(:perform_later)

        described_class.new.perform(mode: :latest)

        expect(GenerateInterpretationsJob).to have_received(:perform_later).twice
      end

      it 'does not queue interpretation jobs for updated stories' do
        allow(GenerateInterpretationsJob).to receive(:perform_later)

        described_class.new.perform(mode: :latest)

        # Should only be called for the 2 new stories, not the 1 updated
        expect(GenerateInterpretationsJob).to have_received(:perform_later).exactly(2).times
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

      it 'does not queue any interpretation jobs' do
        allow(GenerateInterpretationsJob).to receive(:perform_later)

        described_class.new.perform(mode: :latest)

        expect(GenerateInterpretationsJob).not_to have_received(:perform_later)
      end
    end
  end
end
