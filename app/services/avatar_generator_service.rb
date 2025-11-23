# Service to generate persona avatars using DALL-E
class AvatarGeneratorService
  class AvatarGenerationError < StandardError; end

  def initialize(persona)
    @persona = persona
  end

  def generate!
    # Skip if avatar already exists
    return @persona.avatar_url if @persona.avatar_url.present?

    # Skip if no OpenAI API key
    unless ENV["OPENAI_API_KEY"].present?
      Rails.logger.warn "⚠️  No OPENAI_API_KEY found, skipping avatar generation for #{@persona.name}"
      return nil
    end

    Rails.logger.info "🎨 Generating avatar for persona: #{@persona.name}..."

    # Generate avatar using DALL-E
    image_url = generate_with_dalle

    if image_url
      # Update persona with the generated avatar URL
      @persona.update!(avatar_url: image_url)
      Rails.logger.info "  ✅ Avatar generated and saved for #{@persona.name}"
      image_url
    else
      Rails.logger.error "  ❌ Failed to generate avatar for #{@persona.name}"
      nil
    end
  rescue => e
    Rails.logger.error "  ❌ Avatar generation error for #{@persona.name}: #{e.message}"
    raise AvatarGenerationError, "Failed to generate avatar: #{e.message}"
  end

  private

  def generate_with_dalle
    require 'httparty'

    # Build a descriptive prompt based on persona characteristics
    prompt = build_avatar_prompt

    Rails.logger.info "  🎨 DALL-E prompt: #{prompt[0..100]}..."

    # Call DALL-E API
    response = HTTParty.post(
      'https://api.openai.com/v1/images/generations',
      headers: {
        'Authorization' => "Bearer #{ENV['OPENAI_API_KEY']}",
        'Content-Type' => 'application/json'
      },
      body: {
        model: 'dall-e-3',
        prompt: prompt,
        n: 1,
        size: '1024x1024',
        quality: 'standard',
        style: 'vivid'
      }.to_json,
      timeout: 60
    )

    if response.success?
      image_url = response.parsed_response.dig('data', 0, 'url')
      Rails.logger.info "  ✓ DALL-E generated image URL"
      image_url
    else
      error_message = response.parsed_response&.dig('error', 'message') || response.code
      Rails.logger.error "  ✗ DALL-E API error: #{error_message}"
      nil
    end
  rescue => e
    Rails.logger.error "  ✗ Error calling DALL-E API: #{e.message}"
    nil
  end

  def build_avatar_prompt
    # Extract key characteristics from persona
    name = @persona.name
    description = @persona.description || ""
    system_prompt = @persona.system_prompt || ""

    # Analyze the persona to determine visual style
    worldview_keywords = extract_worldview_keywords(description, system_prompt)

    # Build a detailed prompt for DALL-E
    base_prompt = "Create a professional, cartoonish avatar portrait for a persona named '#{name}'. "
    
    # Add description context
    if description.present?
      base_prompt += "This persona is described as: #{description}. "
    end

    # Add worldview-based visual cues
    base_prompt += "Visual style: #{worldview_keywords}. "

    # Standard styling instructions
    base_prompt += "The avatar should be: expressive, memorable, suitable for a news commentary app, "
    base_prompt += "clean background, facing forward, professional illustration style, vibrant colors. "
    base_prompt += "Do not include any text or labels in the image."

    base_prompt
  end

  def extract_worldview_keywords(description, system_prompt)
    combined_text = "#{description} #{system_prompt}".downcase

    # Map common themes to visual styles
    case combined_text
    when /revolutionary|radical|activist|protest|change/
      "bold, determined expression, raised fist energy, revolutionary colors (red, black)"
    when /moderate|centrist|balanced|pragmatic|nuanced/
      "calm, thoughtful expression, professional attire, neutral tones"
    when /patriot|american|flag|freedom|liberty/
      "proud, confident expression, red white and blue accents, stars and stripes subtle elements"
    when /skeptic|conspiracy|question|truth|wake up/
      "suspicious, questioning expression, detective-like, magnifying glass energy, dark mysterious tones"
    when /tech|disrupt|innovation|startup|silicon/
      "modern, futuristic, tech-savvy expression, sleek design, blue and purple tech colors"
    when /burnt.?out|tired|exhausted|doom|anxiety/
      "weary, tired expression, coffee cup energy, muted colors, relatable exhaustion"
    when /conservative|traditional|values/
      "serious, traditional expression, classic attire, traditional colors"
    when /liberal|progressive|social justice/
      "passionate, empathetic expression, inclusive energy, diverse colors"
    else
      # Default style based on name or generic
      "expressive, unique personality, colorful and engaging"
    end
  end
end

