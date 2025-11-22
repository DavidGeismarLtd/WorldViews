# Service to interact with LLM APIs using ruby_llm gem (OpenAI primary, Anthropic fallback)
class LlmClientService
  class LlmError < StandardError; end

  def initialize
    # Configure ruby_llm with API keys
    RubyLLM.configure do |config|
      config.openai_api_key = ENV["OPENAI_API_KEY"]
      config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
    end
  end

  def generate_interpretation(news_summary:, persona_prompt:, max_tokens: 500)
    # Use mock responses in development if no API keys
    if (ENV["OPENAI_API_KEY"].blank? && ENV["ANTHROPIC_API_KEY"].blank?)
      return generate_mock_interpretation(news_summary, persona_prompt)
    end

    # Try OpenAI first
    generate_with_openai(news_summary, persona_prompt, max_tokens)
  end

  private

  def generate_mock_interpretation(news_summary, persona_prompt)
    Rails.logger.info "🎭 Using mock LLM response"

    # Detect persona type from prompt
    persona_type = detect_persona_type(persona_prompt)

    # Generate contextual mock response
    mock_content = generate_mock_content(persona_type, news_summary)

    {
      content: mock_content,
      model: "mock-gpt-4-turbo",
      tokens_used: rand(100..300),
      generation_time_ms: rand(500..1500),
      provider: "mock"
    }
  end

  def detect_persona_type(prompt)
    case prompt.downcase
    when /revolutionary|leftist|anti-capitalist|class struggle/
      :revolutionary
    when /moderate|centrist|balanced|rational/
      :moderate
    when /patriot|conservative|nationalist|tradition/
      :patriot
    when /skeptic|conspiracy|hidden agenda/
      :skeptic
    when /disruptor|tech|silicon valley|innovation/
      :disruptor
    when /burnt out|millennial|gen-z|exhausted/
      :burnt_out
    else
      :moderate
    end
  end

  def generate_mock_content(persona_type, news_summary)
    # Extract key topic from summary
    topic = news_summary.split(".").first

    case persona_type
    when :revolutionary
      "This is just another example of how the capitalist elite consolidates power while workers get screwed. #{topic}? Follow the money—it always leads back to billionaires protecting their interests. We need radical change, not incremental reforms!"

    when :moderate
      "Look, everyone's overreacting here. #{topic} requires a nuanced, data-driven approach. Both extremes are missing the point. We need measured policy solutions, not emotional grandstanding. Let's focus on what actually works."

    when :patriot
      "Finally, some common sense! #{topic} shows why we need to put America first and stop letting foreign interests dictate our future. This is about protecting our values, our jobs, and our sovereignty. God bless America!"

    when :skeptic
      "Wake up, people. #{topic}? That's exactly what THEY want you to focus on while the real agenda unfolds behind closed doors. Connect the dots. This isn't coincidence—it's coordinated. Question everything."

    when :disruptor
      "This is HUGE for the innovation ecosystem! #{topic} is a paradigm shift that will 10x the market. We're talking exponential growth, massive disruption, and game-changing synergies. Time to move fast and break things!"

    when :burnt_out
      "Cool, cool. #{topic}. Another thing to add to the list of reasons we're all doomed. At this point I'm just here for the memes and the existential dread. Someone wake me up when the simulation ends lol."

    else
      "Interesting development. #{topic} certainly raises important questions about our society and where we're headed. Time will tell how this plays out."
    end
  end

  def generate_with_openai(news_summary, persona_prompt, max_tokens)
    Rails.logger.info "🤖 Generating interpretation with OpenAI GPT-4..."

    start_time = Time.current

    # Create a chat instance with OpenAI GPT-4
    chat = RubyLLM.chat(model: "gpt-4-turbo-preview")

    # Set system prompt (persona) using with_instructions
    chat.with_instructions(persona_prompt)

    # Ask the question
    response = chat.ask("React to this news: #{news_summary}")

    generation_time = ((Time.current - start_time) * 1000).to_i

    {
      content: response.content,
      model: response.model_id || "gpt-4-turbo-preview",
      tokens_used: (response.input_tokens || 0) + (response.output_tokens || 0),
      generation_time_ms: generation_time,
      provider: "openai"
    }
  end

  def generate_with_anthropic(news_summary, persona_prompt, max_tokens)
    Rails.logger.info "🤖 Generating interpretation with Anthropic Claude..."

    start_time = Time.current

    # Create a chat instance with Claude
    chat = RubyLLM.chat(model: "claude-3-sonnet-20240229")

    # Set system prompt (persona) using with_instructions
    chat.with_instructions(persona_prompt)

    # Ask the question
    response = chat.ask("React to this news: #{news_summary}")

    generation_time = ((Time.current - start_time) * 1000).to_i

    {
      content: response.content,
      model: response.model_id || "claude-3-sonnet-20240229",
      tokens_used: (response.input_tokens || 0) + (response.output_tokens || 0),
      generation_time_ms: generation_time,
      provider: "anthropic"
    }
  end
end
