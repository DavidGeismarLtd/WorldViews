require 'rails_helper'

RSpec.describe TweetGeneratorService do
  let(:persona) { create(:persona, :revolutionary) }
  let(:news_story) { create(:news_story, headline: "Tech Giant Announces New Privacy Features") }
  let(:interpretation) do
    create(:interpretation,
      persona: persona,
      news_story: news_story,
      content: "This is just another example of Silicon Valley pretending to care about privacy while they continue to exploit our data for profit. The capitalist class will never truly protect workers' digital rights because surveillance is fundamental to their business model. We need collective ownership of our data and democratic control over these tech monopolies!"
    )
  end
  let(:service) { described_class.new(persona: persona, interpretation: interpretation, news_story: news_story) }

  let(:mock_llm_response) do
    {
      content: "✊ Big Tech's 'privacy features' are just another capitalist smokescreen while they keep exploiting our data!",
      model: "gpt-4-turbo-preview",
      tokens_used: 50,
      generation_time_ms: 800,
      provider: "openai"
    }
  end

  before do
    # Mock LlmClientService
    allow_any_instance_of(LlmClientService).to receive(:chat).and_return(mock_llm_response)
  end

  describe '#initialize' do
    it 'sets persona, interpretation, and news_story' do
      expect(service.instance_variable_get(:@persona)).to eq(persona)
      expect(service.instance_variable_get(:@interpretation)).to eq(interpretation)
      expect(service.instance_variable_get(:@news_story)).to eq(news_story)
    end

    it 'initializes LlmClientService' do
      expect(service.instance_variable_get(:@llm_client)).to be_a(LlmClientService)
    end
  end

  describe '#generate_tweet' do
    it 'calls LlmClientService with correct parameters' do
      llm_client = instance_double(LlmClientService)
      allow(LlmClientService).to receive(:new).and_return(llm_client)

      expect(llm_client).to receive(:chat).with(
        system_prompt: kind_of(String),
        user_message: kind_of(String),
        max_tokens: 100
      ).and_return(mock_llm_response)

      described_class.new(persona: persona, interpretation: interpretation, news_story: news_story).generate_tweet
    end

    it 'returns tweet text without URL' do
      result = service.generate_tweet
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end

    it 'includes persona emoji in the generated tweet' do
      result = service.generate_tweet
      expect(result).to include("✊") # Revolutionary emoji
    end

    it 'removes surrounding quotes from LLM response' do
      quoted_response = mock_llm_response.merge(content: '"This is a quoted tweet"')
      allow_any_instance_of(LlmClientService).to receive(:chat).and_return(quoted_response)

      result = service.generate_tweet
      expect(result).to eq("This is a quoted tweet")
    end

    it 'logs the generation process' do
      expect(Rails.logger).to receive(:info).with("🐦 Generating tweet for #{persona.name}...").at_least(:once)
      allow(Rails.logger).to receive(:info) # Allow other log messages
      service.generate_tweet
    end

    context 'when tweet is too long' do
      let(:long_tweet_response) do
        mock_llm_response.merge(
          content: "A" * 300 # Way too long for a tweet
        )
      end

      before do
        allow_any_instance_of(LlmClientService).to receive(:chat).and_return(long_tweet_response)
      end

      it 'truncates the tweet to fit Twitter limits' do
        result = service.generate_tweet
        # Max length is 280 - 37 (for emoji, newlines, URL, buffer) = 243
        expect(result.length).to be <= 243
      end

      it 'adds ellipsis when truncating' do
        result = service.generate_tweet
        expect(result).to end_with("...")
      end
    end

    context 'with different personas' do
      let(:moderate_persona) { create(:persona, :moderate) }
      let(:moderate_service) do
        described_class.new(
          persona: moderate_persona,
          interpretation: interpretation,
          news_story: news_story
        )
      end

      it 'uses the correct persona in system prompt' do
        llm_client = instance_double(LlmClientService)
        allow(LlmClientService).to receive(:new).and_return(llm_client)

        expect(llm_client).to receive(:chat) do |args|
          expect(args[:system_prompt]).to include(moderate_persona.name)
          expect(args[:system_prompt]).to include(moderate_persona.description)
          mock_llm_response
        end

        moderate_service.generate_tweet
      end
    end
  end

  describe 'private methods' do
    describe '#build_system_prompt' do
      it 'includes persona name and description' do
        prompt = service.send(:build_system_prompt)
        expect(prompt).to include(persona.name)
        expect(prompt).to include(persona.description)
      end

      it 'includes instructions for tweet style' do
        prompt = service.send(:build_system_prompt)
        expect(prompt).to include("punchy")
        expect(prompt).to include("engaging")
        expect(prompt).to include("Twitter")
      end

      it 'instructs not to include hashtags or URLs' do
        prompt = service.send(:build_system_prompt)
        expect(prompt).to include("NOT include hashtags")
        expect(prompt).to include("NOT include a URL")
      end
    end

    describe '#build_user_message' do
      it 'includes news headline' do
        message = service.send(:build_user_message)
        expect(message).to include(news_story.headline)
      end

      it 'includes persona name' do
        message = service.send(:build_user_message)
        expect(message).to include(persona.name)
      end

      it 'includes interpretation content' do
        message = service.send(:build_user_message)
        expect(message).to include(interpretation.content)
      end

      it 'provides clear instructions' do
        message = service.send(:build_user_message)
        expect(message).to include("Transform this into a catchy tweet")
      end
    end

    describe '#truncate_for_tweet' do
      it 'returns text as-is when under limit' do
        short_text = "This is a short tweet"
        result = service.send(:truncate_for_tweet, short_text)
        expect(result).to eq(short_text)
      end

      it 'truncates long text and adds ellipsis' do
        long_text = "A" * 300
        result = service.send(:truncate_for_tweet, long_text)
        expect(result.length).to be <= 243 # 280 - 37
        expect(result).to end_with("...")
      end

      it 'removes extra whitespace' do
        messy_text = "This   has    extra     spaces"
        result = service.send(:truncate_for_tweet, messy_text)
        expect(result).to eq("This has extra spaces")
      end

      it 'removes newlines' do
        text_with_newlines = "Line 1\nLine 2\nLine 3"
        result = service.send(:truncate_for_tweet, text_with_newlines)
        expect(result).to eq("Line 1 Line 2 Line 3")
      end

      it 'strips leading and trailing whitespace' do
        text = "  Tweet with spaces  "
        result = service.send(:truncate_for_tweet, text)
        expect(result).to eq("Tweet with spaces")
      end
    end

    describe '#persona_emoji' do
      it 'returns correct emoji for revolutionary' do
        emoji = service.send(:persona_emoji)
        expect(emoji).to eq("✊")
      end

      it 'returns correct emoji for moderate' do
        moderate_persona = create(:persona, :moderate)
        moderate_service = described_class.new(
          persona: moderate_persona,
          interpretation: interpretation,
          news_story: news_story
        )
        emoji = moderate_service.send(:persona_emoji)
        expect(emoji).to eq("⚖️")
      end

      it 'returns correct emoji for patriot' do
        patriot_persona = create(:persona, :patriot)
        patriot_service = described_class.new(
          persona: patriot_persona,
          interpretation: interpretation,
          news_story: news_story
        )
        emoji = patriot_service.send(:persona_emoji)
        expect(emoji).to eq("🇺🇸")
      end

      it 'returns default emoji for unknown persona' do
        unknown_persona = create(:persona, slug: "unknown-persona")
        unknown_service = described_class.new(
          persona: unknown_persona,
          interpretation: interpretation,
          news_story: news_story
        )
        emoji = unknown_service.send(:persona_emoji)
        expect(emoji).to eq("💭")
      end
    end
  end
end
