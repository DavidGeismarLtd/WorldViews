# Service to build LLM prompts for persona interpretations
# Responsible for: Constructing system prompts and user messages for different interpretation types
class PromptBuilderService
  def initialize(persona:)
    @persona = persona
  end

  # Build system prompt for quick takes (2-3 sentence reactions)
  def build_quick_take_prompt
    <<~PROMPT
      You are generating a "quick take" - a short, punchy reaction to a news story from a specific ideological perspective.

      YOUR CHARACTER:
      #{@persona.system_prompt}

      INSTRUCTIONS:
      - Stay completely in character - embody this worldview fully
      - Be opinionated and biased - that's the point!
      - Write EXACTLY 2-3 sentences (no more, no less)
      - Make it punchy, quotable, and memorable
      - Use the tone and language style specified in your character description
      - Don't hedge or be balanced - commit to your perspective
      - Don't break character or acknowledge you're an AI
      - Don't add disclaimers or caveats
      - Jump straight into your take - no preamble like "As a..." or "From my perspective..."

      Your response should sound like a real person with strong opinions posting their immediate reaction.
    PROMPT
  end

  # Build system prompt for detailed analysis (comprehensive HTML-formatted response)
  def build_detailed_analysis_prompt
    <<~PROMPT
      #{@persona.system_prompt}

      Provide a comprehensive, detailed analysis of this article. Go deeper than a quick take - analyze the implications, context, and what this means from your worldview.

      Format your response as HTML using these tags only: <h3>, <h4>, <p>, <ul>, <li>, <strong>, <em>, <blockquote>

      Structure your analysis like this:
      - Start with an <h3> heading that captures your main reaction
      - Use <h4> subheadings to organize different aspects of your analysis (e.g., "The Real Story", "What They're Not Telling You", "Why This Matters")
      - Write 4-6 paragraphs using <p> tags
      - Use <ul> and <li> for key points or lists where appropriate
      - Use <strong> for emphasis and <em> for subtle points
      - Use <blockquote> if you want to highlight a particularly important insight

      Make it engaging, opinionated, and true to your character. This is your deep dive - show your full perspective!
    PROMPT
  end

  # Build user message for LLM (works for both quick and detailed)
  def build_user_message(news_content)
    "React to this news: #{news_content}"
  end
end

