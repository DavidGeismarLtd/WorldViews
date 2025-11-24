require 'rails_helper'

RSpec.describe PromptBuilderService do
  let(:persona) do
    create(:persona,
      name: "The Revolutionary",
      system_prompt: "You are an anti-capitalist activist. You view all events through the lens of class struggle."
    )
  end
  let(:service) { described_class.new(persona: persona) }

  describe '#build_quick_take_prompt' do
    subject(:prompt) { service.build_quick_take_prompt }

    it 'includes the persona system prompt' do
      expect(prompt).to include(persona.system_prompt)
    end

    it 'includes instructions for quick takes' do
      expect(prompt).to include('quick take')
      expect(prompt).to include('2-3 sentences')
    end

    it 'instructs to stay in character' do
      expect(prompt).to include('Stay completely in character')
    end

    it 'instructs to be opinionated' do
      expect(prompt).to include('opinionated and biased')
    end

    it 'instructs not to break character' do
      expect(prompt).to include("Don't break character")
    end

    it 'instructs to avoid preambles' do
      expect(prompt).to include('no preamble')
    end

    it 'returns a string' do
      expect(prompt).to be_a(String)
    end

    it 'is not empty' do
      expect(prompt).not_to be_empty
    end
  end

  describe '#build_detailed_analysis_prompt' do
    subject(:prompt) { service.build_detailed_analysis_prompt }

    it 'includes the persona system prompt' do
      expect(prompt).to include(persona.system_prompt)
    end

    it 'includes instructions for detailed analysis' do
      expect(prompt).to include('comprehensive, detailed analysis')
    end

    it 'includes HTML formatting instructions' do
      expect(prompt).to include('<h3>')
      expect(prompt).to include('<h4>')
      expect(prompt).to include('<p>')
      expect(prompt).to include('<ul>')
      expect(prompt).to include('<li>')
    end

    it 'instructs to use specific HTML tags only' do
      expect(prompt).to include('these tags only')
    end

    it 'includes structure guidance' do
      expect(prompt).to include('Structure your analysis')
    end

    it 'returns a string' do
      expect(prompt).to be_a(String)
    end

    it 'is not empty' do
      expect(prompt).not_to be_empty
    end
  end

  describe '#build_user_message' do
    let(:news_content) { "Tech giant announces record profits amid layoffs." }
    subject(:message) { service.build_user_message(news_content) }

    it 'includes the news content' do
      expect(message).to include(news_content)
    end

    it 'includes "React to this news" instruction' do
      expect(message).to include('React to this news')
    end

    it 'returns a string' do
      expect(message).to be_a(String)
    end

    it 'formats the message correctly' do
      expect(message).to eq("React to this news: #{news_content}")
    end
  end

  describe 'integration with different personas' do
    let(:moderate_persona) do
      create(:persona,
        name: "The Moderate",
        system_prompt: "You are a centrist who values balanced, data-driven approaches."
      )
    end
    let(:moderate_service) { described_class.new(persona: moderate_persona) }

    it 'builds different prompts for different personas' do
      revolutionary_prompt = service.build_quick_take_prompt
      moderate_prompt = moderate_service.build_quick_take_prompt

      expect(revolutionary_prompt).to include('anti-capitalist')
      expect(moderate_prompt).to include('centrist')
      expect(revolutionary_prompt).not_to eq(moderate_prompt)
    end
  end
end

