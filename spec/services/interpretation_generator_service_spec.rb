require 'rails_helper'

RSpec.describe InterpretationGeneratorService do
  let(:news_story) { create(:news_story) }
  let(:persona) { create(:persona) }
  let(:service) { described_class.new(news_story: news_story, persona: persona) }

  let(:mock_llm_response) do
    {
      content: "This is a test interpretation from the LLM.",
      model: "gpt-4-turbo-preview",
      tokens_used: 150,
      generation_time_ms: 1200,
      provider: "openai"
    }
  end

  before do
    # Clear cache before each test
    Rails.cache.clear
  end

  describe '#initialize' do
    it 'initializes with news_story and persona' do
      expect(service.instance_variable_get(:@news_story)).to eq(news_story)
      expect(service.instance_variable_get(:@persona)).to eq(persona)
    end

    it 'initializes helper services' do
      expect(service.instance_variable_get(:@llm_client)).to be_a(LlmClientService)
      expect(service.instance_variable_get(:@prompt_builder)).to be_a(PromptBuilderService)
      expect(service.instance_variable_get(:@content_builder)).to be_a(NewsContentBuilderService)
    end
  end

  describe '#generate!' do
    context 'when interpretation already exists' do
      let!(:existing_interpretation) do
        create(:interpretation, news_story: news_story, persona: persona)
      end

      it 'returns the existing interpretation' do
        result = service.generate!
        expect(result).to eq(existing_interpretation)
      end

      it 'does not call the LLM' do
        expect_any_instance_of(LlmClientService).not_to receive(:chat)
        service.generate!
      end

      it 'does not create a new interpretation' do
        expect {
          service.generate!
        }.not_to change(Interpretation, :count)
      end
    end

    context 'when interpretation is cached' do
      around do |example|
        # Temporarily use memory store instead of null store for caching tests
        original_cache = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        example.run
        Rails.cache = original_cache
      end

      it 'uses cached result and does not call LLM on second generation' do
        # Mock LLM to track calls
        llm_call_count = 0
        allow_any_instance_of(LlmClientService).to receive(:chat) do
          llm_call_count += 1
          mock_llm_response
        end

        # First generation - will call LLM and cache
        first_result = service.generate!
        expect(first_result.content).to eq(mock_llm_response[:content])
        expect(first_result.cached).to be false
        expect(llm_call_count).to eq(1)

        # Verify cache was written
        cache_key = "interpretation/#{news_story.id}/#{persona.id}/quick/v3"
        cached_data = Rails.cache.read(cache_key)
        expect(cached_data).to be_present
        expect(cached_data[:content]).to eq(mock_llm_response[:content])

        # Clear the interpretation but keep cache
        first_result.destroy

        # Create new service instance to simulate fresh request
        new_service = described_class.new(news_story: news_story, persona: persona)

        # Second generation - should use cache, not call LLM
        second_result = new_service.generate!
        expect(second_result.content).to eq(mock_llm_response[:content])
        expect(second_result.cached).to be true
        expect(llm_call_count).to eq(1) # Should still be 1, not 2
      end
    end

    context 'when generating new interpretation' do
      before do
        # Mock LLM to return response
        allow_any_instance_of(LlmClientService).to receive(:chat).and_return(mock_llm_response)
      end

      it 'calls LLM client with correct parameters' do
        llm_client = instance_double(LlmClientService)
        allow(LlmClientService).to receive(:new).and_return(llm_client)
        allow(llm_client).to receive(:chat).and_return(mock_llm_response)

        prompt_builder = instance_double(PromptBuilderService)
        allow(PromptBuilderService).to receive(:new).and_return(prompt_builder)
        allow(prompt_builder).to receive(:build_quick_take_prompt).and_return("System prompt")
        allow(prompt_builder).to receive(:build_user_message).and_return("User message")

        content_builder = instance_double(NewsContentBuilderService)
        allow(NewsContentBuilderService).to receive(:new).and_return(content_builder)
        allow(content_builder).to receive(:for_quick_take).and_return("News content")

        expect(llm_client).to receive(:chat).with(
          system_prompt: "System prompt",
          user_message: "User message"
        )

        described_class.new(news_story: news_story, persona: persona).generate!
      end

      it 'creates a new interpretation' do
        expect {
          service.generate!
        }.to change(Interpretation, :count).by(1)
      end

      it 'sets interpretation attributes correctly' do
        result = service.generate!

        expect(result.news_story).to eq(news_story)
        expect(result.persona).to eq(persona)
        expect(result.content).to eq(mock_llm_response[:content])
        expect(result.llm_model).to eq(mock_llm_response[:model])
        expect(result.llm_tokens_used).to eq(mock_llm_response[:tokens_used])
        expect(result.generation_time_ms).to eq(mock_llm_response[:generation_time_ms])
        expect(result.cached).to be false
      end

      it 'caches the result' do
        cache_key = "interpretation/#{news_story.id}/#{persona.id}/quick/v3"
        expect(Rails.cache).to receive(:write).with(cache_key, mock_llm_response, expires_in: 30.days)
        service.generate!
      end

      it 'stores metadata' do
        result = service.generate!
        expect(result.metadata['provider']).to eq('openai')
        expect(result.metadata['generated_at']).to be_present
      end
    end
  end

  describe '#generate_detailed!' do
    let!(:interpretation) { create(:interpretation, news_story: news_story, persona: persona) }
    let(:full_content) { "Full article content here..." }

    before do
      allow(news_story).to receive(:fetch_full_content).and_return(full_content)
    end

    context 'when detailed content already exists' do
      before do
        interpretation.update!(detailed_content: "<h3>Existing detailed content</h3>")
      end

      it 'returns the existing interpretation' do
        result = service.generate_detailed!
        expect(result).to eq(interpretation)
      end

      it 'does not call the LLM' do
        expect_any_instance_of(LlmClientService).not_to receive(:chat)
        service.generate_detailed!
      end
    end

    context 'when basic interpretation does not exist' do
      before do
        interpretation.destroy
      end

      it 'creates basic interpretation first' do
        expect(service).to receive(:generate!).and_call_original
        service.generate_detailed!
      end
    end

    context 'when detailed content is cached' do
      around do |example|
        # Temporarily use memory store instead of null store for caching tests
        original_cache = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        example.run
        Rails.cache = original_cache
      end

      it 'uses cached result and does not call LLM for detailed content' do
        # Mock LLM to track calls
        llm_call_count = 0
        allow_any_instance_of(LlmClientService).to receive(:chat) do
          llm_call_count += 1
          mock_llm_response
        end

        # First detailed generation - will call LLM once for detailed (basic already exists from service fixture)
        first_result = service.generate_detailed!
        first_detailed_content = first_result.detailed_content
        initial_call_count = llm_call_count
        expect(initial_call_count).to be >= 1 # At least one call for detailed

        # Verify detailed cache was written
        cache_key = "interpretation/#{news_story.id}/#{persona.id}/detailed/v3"
        cached_data = Rails.cache.read(cache_key)
        expect(cached_data).to be_present

        # Clear detailed content but keep cache
        first_result.update!(detailed_content: nil)

        # Create new service instance
        new_service = described_class.new(news_story: news_story, persona: persona)

        # Second detailed generation - should use cache, not call LLM again
        second_result = new_service.generate_detailed!
        expect(second_result.detailed_content).to eq(first_detailed_content)
        expect(llm_call_count).to eq(initial_call_count) # Should not increase
      end
    end

    context 'when generating new detailed content' do
      before do
        # Mock LLM to return response
        allow_any_instance_of(LlmClientService).to receive(:chat).and_return(mock_llm_response)
      end

      it 'fetches full article content' do
        expect(news_story).to receive(:fetch_full_content).and_return(full_content)
        service.generate_detailed!
      end

      it 'calls LLM with detailed analysis prompt' do
        llm_client = instance_double(LlmClientService)
        allow(LlmClientService).to receive(:new).and_return(llm_client)
        allow(llm_client).to receive(:chat).and_return(mock_llm_response)

        prompt_builder = instance_double(PromptBuilderService)
        allow(PromptBuilderService).to receive(:new).and_return(prompt_builder)
        allow(prompt_builder).to receive(:build_detailed_analysis_prompt).and_return("Detailed prompt")
        allow(prompt_builder).to receive(:build_user_message).and_return("User message")

        content_builder = instance_double(NewsContentBuilderService)
        allow(NewsContentBuilderService).to receive(:new).and_return(content_builder)
        allow(content_builder).to receive(:for_detailed_analysis).and_return("Detailed content")

        expect(llm_client).to receive(:chat).with(
          system_prompt: "Detailed prompt",
          user_message: "User message"
        )

        described_class.new(news_story: news_story, persona: persona).generate_detailed!
      end

      it 'updates interpretation with detailed content' do
        result = service.generate_detailed!
        expect(result.detailed_content).to eq(mock_llm_response[:content])
      end

      it 'caches the detailed result' do
        cache_key = "interpretation/#{news_story.id}/#{persona.id}/detailed/v3"
        expect(Rails.cache).to receive(:write).with(cache_key, mock_llm_response, expires_in: 30.days)
        service.generate_detailed!
      end
    end
  end

  describe 'private methods' do
    describe '#build_cache_key' do
      it 'builds correct cache key for quick take' do
        key = service.send(:build_cache_key, :quick)
        expect(key).to eq("interpretation/#{news_story.id}/#{persona.id}/quick/v3")
      end

      it 'builds correct cache key for detailed' do
        key = service.send(:build_cache_key, :detailed)
        expect(key).to eq("interpretation/#{news_story.id}/#{persona.id}/detailed/v3")
      end
    end

    describe '#create_interpretation' do
      it 'creates interpretation with cached flag' do
        result = service.send(:create_interpretation, mock_llm_response, cached: true)
        expect(result.cached).to be true
      end

      it 'creates interpretation without cached flag' do
        result = service.send(:create_interpretation, mock_llm_response, cached: false)
        expect(result.cached).to be false
      end
    end
  end
end
