require 'rails_helper'

RSpec.describe LlmClientService do
  let(:service) { described_class.new }
  let(:system_prompt) { "You are a helpful assistant." }
  let(:user_message) { "What is the capital of France?" }

  before do
    # Mock RubyLLM configuration
    config_double = double('Config')
    allow(config_double).to receive(:openai_api_key=)
    allow(config_double).to receive(:anthropic_api_key=)
    allow(RubyLLM).to receive(:configure).and_yield(config_double)
  end

  describe '#initialize' do
    it 'configures RubyLLM with API keys' do
      expect(RubyLLM).to receive(:configure)
      described_class.new
    end
  end

  describe '#chat' do
    context 'when no API keys are configured' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
        allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return(nil)
      end

      it 'returns a mock response' do
        result = service.chat(system_prompt: system_prompt, user_message: user_message)

        expect(result).to be_a(Hash)
        expect(result[:content]).to be_a(String)
        expect(result[:model]).to eq('mock-gpt-4-turbo')
        expect(result[:provider]).to eq('mock')
        expect(result[:tokens_used]).to be_a(Integer)
        expect(result[:generation_time_ms]).to be_a(Integer)
      end

      it 'includes user message context in mock response' do
        result = service.chat(system_prompt: system_prompt, user_message: user_message)
        expect(result[:content]).to include('Mock response')
      end
    end

    context 'when OpenAI API key is configured' do
      let(:mock_chat) { double('RubyLLM::Chat') }
      let(:mock_response) do
        double('Response',
          content: 'The capital of France is Paris.',
          model_id: 'gpt-4-turbo-preview',
          input_tokens: 20,
          output_tokens: 10
        )
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-key')
        allow(RubyLLM).to receive(:chat).and_return(mock_chat)
        allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
        allow(mock_chat).to receive(:ask).and_return(mock_response)
      end

      it 'calls OpenAI with correct parameters' do
        expect(RubyLLM).to receive(:chat).with(model: 'gpt-4-turbo-preview')
        expect(mock_chat).to receive(:with_instructions).with(system_prompt)
        expect(mock_chat).to receive(:ask).with(user_message)

        service.chat(system_prompt: system_prompt, user_message: user_message)
      end

      it 'returns formatted response' do
        result = service.chat(system_prompt: system_prompt, user_message: user_message)

        expect(result[:content]).to eq('The capital of France is Paris.')
        expect(result[:model]).to eq('gpt-4-turbo-preview')
        expect(result[:tokens_used]).to eq(30)
        expect(result[:provider]).to eq('openai')
        expect(result[:generation_time_ms]).to be_a(Integer)
      end

      it 'calculates total tokens correctly' do
        result = service.chat(system_prompt: system_prompt, user_message: user_message)
        expect(result[:tokens_used]).to eq(20 + 10)
      end
    end

    context 'when OpenAI fails and Anthropic is available' do
      let(:mock_chat) { double('RubyLLM::Chat') }
      let(:mock_response) do
        double('Response',
          content: 'Paris is the capital of France.',
          model_id: 'claude-3-sonnet-20240229',
          input_tokens: 25,
          output_tokens: 15
        )
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-key')
        allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return('test-key')

        # OpenAI fails
        allow(RubyLLM).to receive(:chat).with(model: 'gpt-4-turbo-preview').and_raise(StandardError, 'OpenAI error')

        # Anthropic succeeds
        allow(RubyLLM).to receive(:chat).with(model: 'claude-3-sonnet-20240229').and_return(mock_chat)
        allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
        allow(mock_chat).to receive(:ask).and_return(mock_response)
      end

      it 'falls back to Anthropic' do
        expect(RubyLLM).to receive(:chat).with(model: 'gpt-4-turbo-preview')
        expect(RubyLLM).to receive(:chat).with(model: 'claude-3-sonnet-20240229')

        result = service.chat(system_prompt: system_prompt, user_message: user_message)
        expect(result[:provider]).to eq('anthropic')
      end
    end

    context 'when all providers fail' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-key')
        allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return('test-key')

        allow(RubyLLM).to receive(:chat).and_raise(StandardError, 'API error')
      end

      it 'raises LlmError' do
        expect {
          service.chat(system_prompt: system_prompt, user_message: user_message)
        }.to raise_error(LlmClientService::LlmError, /All LLM providers failed/)
      end
    end
  end
end
