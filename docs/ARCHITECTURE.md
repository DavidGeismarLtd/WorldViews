# Worldviews - Technical Architecture

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                          │
│  (Hotwire/Turbo + Stimulus + Tailwind CSS)                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Rails Application                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Controllers  │  │   Services   │  │  Background  │         │
│  │              │  │              │  │     Jobs     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │    Models    │  │    Helpers   │  │   Mailers    │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Data & Cache Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  PostgreSQL  │  │ Solid Cache  │  │ Solid Queue  │         │
│  │   (Primary)  │  │              │  │              │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      External Services                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   News API   │  │   LLM API    │  │   CDN/S3     │         │
│  │  (NewsAPI)   │  │ (OpenAI/     │  │  (Assets)    │         │
│  │              │  │  Anthropic)  │  │              │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## Database Schema

### Core Tables

#### `news_stories`
```ruby
# Stores fetched news articles
- id (bigint, primary key)
- external_id (string, unique) # API's story ID
- headline (string, not null)
- summary (text)
- full_content (text)
- source (string) # e.g., "BBC", "Reuters"
- source_url (string)
- published_at (datetime)
- category (string) # "politics", "tech", "world", etc.
- image_url (string)
- featured (boolean, default: false)
- active (boolean, default: true)
- metadata (jsonb) # Additional API data
- created_at (datetime)
- updated_at (datetime)

# Indexes
- index on external_id (unique)
- index on published_at
- index on category
- index on featured, active
```

#### `personas`
```ruby
# Defines ideological personas
- id (bigint, primary key)
- name (string, not null) # "Hardcore Leftist Firebrand"
- slug (string, unique) # "leftist-firebrand"
- description (text) # Public-facing description
- system_prompt (text, not null) # LLM instruction
- avatar_url (string)
- color_primary (string) # Hex color for UI
- color_secondary (string)
- display_order (integer) # For sorting
- active (boolean, default: true)
- created_at (datetime)
- updated_at (datetime)

# Indexes
- index on slug (unique)
- index on display_order
- index on active
```

#### `interpretations`
```ruby
# Stores LLM-generated persona reactions
- id (bigint, primary key)
- news_story_id (bigint, foreign key)
- persona_id (bigint, foreign key)
- content (text, not null) # The interpretation
- llm_model (string) # "gpt-4", "claude-3-opus", etc.
- llm_tokens_used (integer)
- generation_time_ms (integer)
- cached (boolean, default: false)
- quality_score (decimal) # Optional: for filtering
- metadata (jsonb) # LLM response metadata
- created_at (datetime)
- updated_at (datetime)

# Indexes
- index on [news_story_id, persona_id] (unique)
- index on news_story_id
- index on persona_id
- index on created_at
```

#### `users` (Future)
```ruby
# User accounts
- id (bigint, primary key)
- email (string, unique)
- encrypted_password (string)
- name (string)
- avatar_url (string)
- subscription_tier (string) # "free", "premium"
- subscription_expires_at (datetime)
- preferences (jsonb) # UI settings, favorite personas
- created_at (datetime)
- updated_at (datetime)
```

#### `shares` (Analytics)
```ruby
# Track social shares
- id (bigint, primary key)
- interpretation_id (bigint, foreign key)
- platform (string) # "twitter", "facebook", etc.
- share_type (string) # "single", "comparison"
- user_id (bigint, foreign key, nullable)
- created_at (datetime)

# Indexes
- index on interpretation_id
- index on platform
- index on created_at
```

#### `reactions` (Engagement)
```ruby
# User reactions to interpretations
- id (bigint, primary key)
- interpretation_id (bigint, foreign key)
- user_id (bigint, foreign key, nullable)
- reaction_type (string) # "funny", "accurate", "wtf"
- session_id (string) # For anonymous users
- created_at (datetime)

# Indexes
- index on interpretation_id
- index on [user_id, interpretation_id] (unique)
- index on [session_id, interpretation_id] (unique)
```

---

## Application Structure

### Models

```
app/models/
├── news_story.rb
│   ├── Validations (headline, source, published_at)
│   ├── Scopes (featured, recent, by_category)
│   ├── Associations (has_many :interpretations)
│   └── Methods (fetch_interpretations, featured?, trending?)
│
├── persona.rb
│   ├── Validations (name, system_prompt)
│   ├── Scopes (active, ordered)
│   ├── Associations (has_many :interpretations)
│   └── Methods (generate_interpretation, prompt_template)
│
├── interpretation.rb
│   ├── Validations (content, news_story, persona)
│   ├── Associations (belongs_to :news_story, :persona)
│   └── Methods (generate!, cache_key, shareable_image)
│
├── user.rb (Future)
│   ├── Devise modules
│   ├── Associations (has_many :reactions, :shares)
│   └── Methods (premium?, can_view_story?)
│
└── concerns/
    ├── shareable.rb
    └── cacheable.rb
```

### Controllers

```
app/controllers/
├── application_controller.rb
│   └── Common authentication, error handling
│
├── news_stories_controller.rb
│   ├── index  # Browse stories
│   ├── show   # Story detail with interpretations
│   └── featured # Today's featured story
│
├── interpretations_controller.rb
│   ├── show   # Single interpretation
│   └── compare # Side-by-side comparison
│
├── personas_controller.rb
│   ├── index  # Browse personas
│   └── show   # Persona detail
│
├── shares_controller.rb
│   └── create # Track share events
│
└── api/
    └── v1/
        ├── news_stories_controller.rb
        └── interpretations_controller.rb
```

### Services

```
app/services/
├── news_fetcher_service.rb
│   ├── fetch_latest_news
│   ├── parse_api_response
│   └── create_or_update_stories
│
├── interpretation_generator_service.rb
│   ├── generate_for_story(news_story, persona)
│   ├── call_llm_api
│   ├── parse_llm_response
│   └── cache_interpretation
│
├── llm_client_service.rb
│   ├── OpenAI adapter
│   ├── Anthropic adapter
│   ├── Fallback logic
│   └── Rate limiting
│
└── share_image_generator_service.rb
    ├── generate_single_card
    ├── generate_comparison_grid
    └── upload_to_storage
```

### Background Jobs

```
app/jobs/
├── fetch_news_job.rb
│   └── Runs every 6 hours, fetches latest news
│
├── generate_interpretations_job.rb
│   └── Generates interpretations for new stories
│
├── cleanup_old_stories_job.rb
│   └── Archives stories older than 30 days
│
└── daily_digest_job.rb (Future)
    └── Sends email digest to subscribers
```

---

## External Integrations

### News API Integration

**Primary: NewsAPI.org**
- Free tier: 100 requests/day
- Endpoint: `/v2/top-headlines`
- Categories: business, technology, politics, science
- Language: English (expandable)

**Backup: GNews API**
- Free tier: 100 requests/day
- Similar structure to NewsAPI

**Implementation:**
```ruby
# config/initializers/news_api.rb
NEWS_API_KEY = ENV['NEWS_API_KEY']
NEWS_API_URL = 'https://newsapi.org/v2'

# app/services/news_fetcher_service.rb
class NewsFetcherService
  def fetch_latest_news(category: 'general', limit: 10)
    # API call logic
  end
end
```

### LLM API Integration

**Primary: OpenAI GPT-4**
- Model: `gpt-4-turbo-preview`
- Max tokens: 500 per interpretation
- Temperature: 0.8 (creative but consistent)

**Backup: Anthropic Claude**
- Model: `claude-3-sonnet`
- Similar parameters

**Implementation:**
```ruby
# app/services/llm_client_service.rb
class LlmClientService
  def generate_interpretation(prompt:, max_tokens: 500)
    # Try OpenAI first
    # Fall back to Anthropic if needed
    # Cache responses
  end
end
```

---

## Caching Strategy

### Multi-Level Caching

1. **HTTP Caching** (Turbo)
   - Cache story pages for 5 minutes
   - Invalidate on new interpretations

2. **Fragment Caching** (Rails)
   - Cache persona cards
   - Cache interpretation content
   - Cache comparison grids

3. **Database Caching** (Solid Cache)
   - Cache LLM responses indefinitely
   - Cache news API responses for 6 hours

4. **CDN Caching**
   - Static assets (images, CSS, JS)
   - Generated share images

**Cache Keys:**
```ruby
# Interpretation cache
"interpretation/#{news_story.id}/#{persona.id}/v1"

# Story page cache
"story/#{news_story.id}/#{news_story.updated_at.to_i}"

# Persona list cache
"personas/active/#{Persona.maximum(:updated_at).to_i}"
```

---

## Performance Optimization

### Database Optimization
- Eager loading: `NewsStory.includes(:interpretations, :personas)`
- Database indexes on foreign keys and query columns
- Partial indexes for active records only
- JSONB indexes for metadata queries

### Background Processing
- Generate interpretations asynchronously
- Batch process multiple personas per story
- Rate limit LLM API calls
- Retry failed generations with exponential backoff

### Frontend Optimization
- Lazy load persona interpretations
- Infinite scroll for story browsing
- Image optimization (WebP, responsive sizes)
- Service worker for offline support

---

## Security Considerations

### API Key Management
- Store in Rails credentials (encrypted)
- Rotate keys regularly
- Monitor usage and costs

### Rate Limiting
- Limit API calls per IP
- Implement request throttling
- Queue overflow requests

### Content Moderation
- Filter offensive LLM outputs
- Manual review queue for flagged content
- User reporting system

### Data Privacy
- GDPR compliance for EU users
- Cookie consent
- Data export/deletion tools

