# Service to interact with LLM APIs using ruby_llm gem (OpenAI primary, Anthropic fallback)
# Generic LLM client - no knowledge of specific use cases like "interpretations"
class LlmClientService
  class LlmError < StandardError; end

  def initialize
    # Configure ruby_llm with API keys
    RubyLLM.configure do |config|
      config.openai_api_key = ENV["OPENAI_API_KEY"]
      config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
    end
  end

  # Generic chat method - can be used for any LLM interaction
  # @param system_prompt [String] The system prompt/instructions for the LLM
  # @param user_message [String] The user's message/question
  # @param max_tokens [Integer] Maximum tokens to generate
  # @return [Hash] Response with :content, :model, :tokens_used, :generation_time_ms, :provider
  def chat(system_prompt:, user_message:, max_tokens: 500)
    # Use mock responses if no API keys available
    return mock_response(user_message) if no_api_keys?

    # Try OpenAI first
    generate_with_openai(system_prompt, user_message, max_tokens)
  end

  private

  def no_api_keys?
    ENV["OPENAI_API_KEY"].blank? && ENV["ANTHROPIC_API_KEY"].blank?
  end

  def mock_response(user_message)
    Rails.logger.info "🎭 Using mock LLM response (no API keys configured)"

    # Extract first sentence for context
    topic = user_message.split(".").first

    {
      content: "Mock response for: #{topic}. This is a simulated LLM response for development/testing purposes.",
      model: "mock-gpt-4-turbo",
      tokens_used: rand(100..300),
      generation_time_ms: rand(500..1500),
      provider: "mock"
    }
  end

  def generate_with_openai(system_prompt, user_message, max_tokens)
    Rails.logger.info "🤖 Generating with OpenAI GPT-4..."

    start_time = Time.current

    # Create a chat instance with OpenAI GPT-4
    chat = RubyLLM.chat(model: "gpt-4-turbo-preview")

    # Set system prompt
    chat.with_instructions(system_prompt)

    # Send user message
    response = chat.ask(user_message)

    generation_time = ((Time.current - start_time) * 1000).to_i

    {
      content: response.content,
      model: response.model_id || "gpt-4-turbo-preview",
      tokens_used: (response.input_tokens || 0) + (response.output_tokens || 0),
      generation_time_ms: generation_time,
      provider: "openai"
    }
  rescue StandardError => e
    Rails.logger.error "❌ OpenAI error: #{e.message}"
    # Fallback to Anthropic
    generate_with_anthropic(system_prompt, user_message, max_tokens)
  end

  def generate_with_anthropic(system_prompt, user_message, max_tokens)
    Rails.logger.info "🤖 Generating with Anthropic Claude..."

    start_time = Time.current

    # Create a chat instance with Claude
    chat = RubyLLM.chat(model: "claude-3-sonnet-20240229")

    # Set system prompt
    chat.with_instructions(system_prompt)

    # Send user message
    response = chat.ask(user_message)

    generation_time = ((Time.current - start_time) * 1000).to_i

    {
      content: response.content,
      model: response.model_id || "claude-3-sonnet-20240229",
      tokens_used: (response.input_tokens || 0) + (response.output_tokens || 0),
      generation_time_ms: generation_time,
      provider: "anthropic"
    }
  rescue StandardError => e
    Rails.logger.error "❌ Anthropic error: #{e.message}"
    raise LlmError, "All LLM providers failed: #{e.message}"
  end
end
