# Service to generate catchy, tweet-vibe content from persona interpretations
# Uses OpenAI to transform longer interpretations into engaging tweets
class TweetGeneratorService
  def initialize(persona:, interpretation:, news_story:)
    @persona = persona
    @interpretation = interpretation
    @news_story = news_story
    @llm_client = LlmClientService.new
  end

  # Generate a tweet-friendly version of the interpretation
  # @return [String] Tweet text (without URL, that's added separately)
  def generate_tweet
    Rails.logger.info "🐦 Generating tweet for #{@persona.name}..."

    # Build the prompt for tweet generation
    system_prompt = build_system_prompt
    user_message = build_user_message

    # Generate tweet using LLM
    result = @llm_client.chat(
      system_prompt: system_prompt,
      user_message: user_message,
      max_tokens: 100  # Tweets are short!
    )

    tweet_text = result[:content].strip

    # Remove quotes if the LLM added them
    tweet_text = tweet_text.gsub(/^["']|["']$/, '')

    # Ensure it fits in a tweet (accounting for emoji + URL)
    truncate_for_tweet(tweet_text)
  end

  private

  def build_system_prompt
    <<~PROMPT
      You are a social media expert helping #{@persona.name} craft engaging tweets.

      #{@persona.name}'s personality: #{@persona.description}

      Your task is to transform their longer analysis into a punchy, engaging tweet that:
      - Captures their unique voice and perspective
      - Is attention-grabbing and shareable
      - Uses their characteristic tone and style
      - Fits Twitter's vibe (casual, direct, opinionated)
      - Is 1-2 sentences maximum
      - Does NOT include hashtags (we'll add those separately)
      - Does NOT include a URL (we'll add that separately)
      - Starts with their signature emoji if appropriate

      Keep it spicy, keep it real, keep it short! 🔥
    PROMPT
  end

  def build_user_message
    <<~MESSAGE
      News headline: #{@news_story.headline}

      #{@persona.name}'s full analysis:
      #{@interpretation.content}

      Transform this into a catchy tweet that captures the essence of their take.
      Make it punchy and engaging while staying true to their voice!
    MESSAGE
  end

  def truncate_for_tweet(text)
    # Twitter counts URLs as 23 characters
    # Leave room for emoji (2), newlines (2), URL (23), and buffer (10)
    max_length = 280 - 37

    # Remove any existing newlines and extra whitespace
    cleaned_text = text.gsub(/\s+/, " ").strip

    if cleaned_text.length > max_length
      # Truncate and add ellipsis (subtract 3 for the "...")
      cleaned_text[0...(max_length - 3)].strip + "..."
    else
      cleaned_text
    end
  end

  def persona_emoji
    # Map personas to emojis for brand consistency
    emoji_map = {
      "revolutionary" => "✊",
      "the-revolutionary" => "✊",
      "moderate" => "⚖️",
      "the-moderate" => "⚖️",
      "patriot" => "🇺🇸",
      "the-patriot" => "🇺🇸",
      "tech-bro" => "🚀",
      "conspiracy-theorist" => "👁️",
      "skeptic" => "🤔",
      "the-skeptic" => "🤔",
      "disruptor" => "💥",
      "the-disruptor" => "💥",
      "burnt-out" => "😮‍💨",
      "the-burnt-out" => "😮‍💨",
      "centrist" => "⚖️",
      "doomer" => "💀",
      "optimist" => "🌟"
    }
    emoji_map[@persona.slug] || "💭"
  end
end
