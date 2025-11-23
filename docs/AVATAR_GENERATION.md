# Persona Avatar Generation

## Overview

When a user creates a custom persona without providing an avatar URL, the system automatically generates a unique avatar using OpenAI's DALL-E 3 API in the background.

## How It Works

### 1. Persona Creation Flow

```
User creates persona → Persona saved → Background job enqueued → DALL-E generates avatar → Avatar URL saved
```

### 2. Components

#### AvatarGeneratorService (`app/services/avatar_generator_service.rb`)
- Generates persona avatars using DALL-E 3
- Builds intelligent prompts based on persona characteristics
- Analyzes persona description and system prompt to determine visual style
- Maps worldview keywords to visual themes (e.g., "revolutionary" → bold colors, raised fist energy)

**Key Features:**
- Skips generation if avatar already exists
- Gracefully handles missing API keys
- Returns the generated image URL from DALL-E
- Updates persona record with the avatar URL

#### GeneratePersonaAvatarJob (`app/sidekiq/generate_persona_avatar_job.rb`)
- Sidekiq background job for async avatar generation
- Runs in the `default` queue
- Retries up to 2 times on failure
- Logs all generation attempts and results

#### Persona Model Callback
```ruby
after_commit :enqueue_avatar_generation, on: :create, if: -> { avatar_url.blank? && !official? }
```
- Automatically triggers avatar generation for new custom personas
- Only runs for non-official personas without avatars
- Uses `after_commit` to ensure the persona is fully saved before job runs

#### PersonasController
```ruby
def create
  @persona = current_user.personas.build(persona_params)
  @persona.official = false

  if @persona.save
    # Generate avatar in background if none provided
    if @persona.avatar_url.blank?
      GeneratePersonaAvatarJob.perform_async(@persona.id)
    end

    redirect_to persona_path(@persona), notice: "🎉 Persona created successfully!"
  else
    render :new, status: :unprocessable_entity
  end
end
```

### 3. Avatar Prompt Generation

The service intelligently builds DALL-E prompts based on persona characteristics:

**Example Worldview Mappings:**
- **Revolutionary/Activist** → Bold, determined expression, revolutionary colors (red, black)
- **Moderate/Centrist** → Calm, thoughtful expression, neutral tones
- **Patriot** → Proud expression, red/white/blue accents
- **Skeptic/Conspiracy** → Suspicious expression, detective-like, mysterious tones
- **Tech/Disruptor** → Modern, futuristic, blue/purple tech colors
- **Burnt Out** → Weary expression, coffee cup energy, muted colors

**Prompt Structure:**
```
Create a professional, cartoonish avatar portrait for a persona named '{name}'.
This persona is described as: {description}.
Visual style: {worldview_keywords}.
The avatar should be: expressive, memorable, suitable for a news commentary app,
clean background, facing forward, professional illustration style, vibrant colors.
Do not include any text or labels in the image.
```

### 4. DALL-E API Configuration

```ruby
{
  model: 'dall-e-3',
  prompt: generated_prompt,
  n: 1,
  size: '1024x1024',
  quality: 'standard',
  style: 'vivid'
}
```

## Usage

### Automatic Generation (Default)
When a user creates a persona through the UI without uploading an avatar, generation happens automatically:

1. User fills out persona form (name, description, system prompt, etc.)
2. User submits without providing `avatar_url`
3. Persona is created and saved
4. Background job is enqueued
5. DALL-E generates avatar based on persona characteristics
6. Avatar URL is saved to persona record

### Manual Generation (Console)
```ruby
# Generate avatar for a specific persona
persona = Persona.find_by(slug: 'my-persona')
AvatarGeneratorService.new(persona).generate!

# Or enqueue as background job
GeneratePersonaAvatarJob.perform_async(persona.id)
```

## Environment Variables

Required:
```bash
OPENAI_API_KEY=sk-...
```

If `OPENAI_API_KEY` is not set, avatar generation will be skipped with a warning log.

## Error Handling

- **Missing API Key**: Logs warning, skips generation
- **DALL-E API Error**: Logs error, retries up to 2 times
- **Network Timeout**: 60-second timeout, retries on failure
- **Persona Not Found**: Logs error, job terminates

## Monitoring

Check Sidekiq dashboard to monitor avatar generation jobs:
```bash
# Development
http://localhost:3000/sidekiq

# Production
https://your-app.com/sidekiq
```

## Cost Considerations

DALL-E 3 pricing (as of 2024):
- Standard quality, 1024x1024: ~$0.04 per image
- Each custom persona creation = 1 image generation

**Optimization:**
- Only generates for custom personas (not official ones)
- Skips if avatar already exists
- No regeneration on persona updates

## Future Enhancements

- [ ] Add avatar preview before saving
- [ ] Allow users to regenerate avatars
- [ ] Cache generated avatars in cloud storage (S3, Cloudinary)
- [ ] Add multiple avatar style options
- [ ] Implement avatar editing/customization

