# Worldviews - Quick Start Guide

## Project Summary

**Worldviews** is a satirical media literacy web app that shows how the same news generates wildly different interpretations through exaggerated ideological personas. Built with Rails 8.1, it fetches real news and uses LLMs to generate persona-specific reactions.

---

## Documentation Index

1. **[PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md)** - High-level concept, features, and roadmap
2. **[USER_FLOW.md](./USER_FLOW.md)** - Detailed user journeys and interaction flows
3. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Technical architecture and database schema
4. **[PERSONAS.md](./PERSONAS.md)** - Persona definitions, prompts, and examples
5. **[DESIGN_BRIEF.md](./DESIGN_BRIEF.md)** - Brand identity, visual design, and UI components
6. **[IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md)** - Week-by-week development plan
7. **[API_SPECIFICATIONS.md](./API_SPECIFICATIONS.md)** - External and internal API documentation

---

## Tech Stack

- **Backend:** Ruby on Rails 8.1
- **Database:** PostgreSQL
- **Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS
- **LLM:** OpenAI GPT-4 / Anthropic Claude
- **News API:** NewsAPI.org
- **Caching:** Solid Cache (Rails 8)
- **Jobs:** Solid Queue (Rails 8)
- **Deployment:** Kamal (Docker)

---

## Quick Setup (Development)

### Prerequisites

```bash
# Required
- Ruby 3.3.5
- PostgreSQL 14+
- Node.js 18+ (for JavaScript)
- Redis (for caching)

# Optional
- Docker (for deployment)
```

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/worldviews.git
cd worldviews

# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Set up environment variables
cp .env.example .env
# Edit .env with your API keys:
# - NEWS_API_KEY (from newsapi.org)
# - OPENAI_API_KEY (from openai.com)

# Start development server
bin/dev
```

Visit `http://localhost:3000`

---

## Core Concepts

### Data Flow

```
News API → NewsStory → Persona + LLM → Interpretation → User
```

1. **Fetch News:** Background job fetches news from NewsAPI every 6 hours
2. **Store Stories:** News articles saved to `news_stories` table
3. **Generate Interpretations:** For each story, LLM generates persona reactions
4. **Cache Results:** Interpretations cached indefinitely
5. **Display to Users:** Users browse stories and swipe through personas

### Key Models

```ruby
NewsStory
  - headline, summary, source, published_at
  - has_many :interpretations

Persona
  - name, slug, system_prompt, color
  - has_many :interpretations

Interpretation
  - content (LLM-generated text)
  - belongs_to :news_story
  - belongs_to :persona
```

---

## Development Workflow

### Adding a New Persona

1. **Create persona record:**
```ruby
# db/seeds.rb or rails console
Persona.create!(
  name: "The Environmentalist",
  slug: "environmentalist",
  description: "Everything through a climate lens",
  system_prompt: "You are a passionate environmental activist...",
  color_primary: "#10B981",
  display_order: 7,
  active: true
)
```

2. **Generate interpretations:**
```ruby
# In rails console
news_story = NewsStory.last
persona = Persona.find_by(slug: 'environmentalist')
GenerateInterpretationsJob.perform_now(news_story.id, persona.id)
```

3. **Test in browser:**
Visit story detail page and verify new persona appears

---

### Fetching New News

```bash
# Manual fetch
rails runner "FetchNewsJob.perform_now"

# Or in rails console
NewsFetcherService.new.fetch_and_store_news
```

---

### Testing LLM Integration

```ruby
# In rails console
service = LlmClientService.new
result = service.generate_interpretation(
  news_summary: "Global tech giant announces record profits",
  persona_prompt: Persona.find_by(slug: 'revolutionary').system_prompt
)

puts result[:content]
# => "Obviously. Another day, another corporate behemoth..."
```

---

## Common Tasks

### Run Tests

```bash
# All tests
bundle exec rspec

# Specific file
bundle exec rspec spec/models/news_story_spec.rb

# With coverage
COVERAGE=true bundle exec rspec
```

### Database Operations

```bash
# Reset database
bin/rails db:reset

# Run migrations
bin/rails db:migrate

# Rollback migration
bin/rails db:rollback

# Seed data
bin/rails db:seed
```

### Background Jobs

```bash
# View job queue
bin/rails solid_queue:status

# Clear failed jobs
bin/rails solid_queue:clear_failed

# Run specific job
bin/rails runner "FetchNewsJob.perform_now"
```

### Caching

```bash
# Clear all caches
bin/rails cache:clear

# Clear specific cache
Rails.cache.delete("interpretation/123/456/v1")
```

---

## Project Structure

```
worldviews/
├── app/
│   ├── controllers/
│   │   ├── news_stories_controller.rb
│   │   ├── interpretations_controller.rb
│   │   └── personas_controller.rb
│   ├── models/
│   │   ├── news_story.rb
│   │   ├── persona.rb
│   │   └── interpretation.rb
│   ├── services/
│   │   ├── news_fetcher_service.rb
│   │   ├── llm_client_service.rb
│   │   └── interpretation_generator_service.rb
│   ├── jobs/
│   │   ├── fetch_news_job.rb
│   │   └── generate_interpretations_job.rb
│   ├── views/
│   │   ├── news_stories/
│   │   ├── interpretations/
│   │   └── personas/
│   └── javascript/
│       └── controllers/
│           └── persona_carousel_controller.js
├── config/
│   ├── routes.rb
│   ├── database.yml
│   └── initializers/
├── db/
│   ├── migrate/
│   └── seeds.rb
├── docs/
│   ├── PROJECT_OVERVIEW.md
│   ├── USER_FLOW.md
│   ├── ARCHITECTURE.md
│   ├── PERSONAS.md
│   ├── DESIGN_BRIEF.md
│   ├── IMPLEMENTATION_PLAN.md
│   └── API_SPECIFICATIONS.md
└── spec/
    ├── models/
    ├── services/
    └── requests/
```

---

## Next Steps

### Immediate (Week 1-2)
1. ✅ Review all documentation
2. [ ] Set up development environment
3. [ ] Create database schema
4. [ ] Implement News API integration
5. [ ] Implement LLM integration
6. [ ] Create seed data with 6 personas

### Short-term (Week 3-4)
1. [ ] Build basic UI (homepage, story detail)
2. [ ] Implement persona carousel
3. [ ] Add caching layer
4. [ ] Deploy to staging

### Medium-term (Week 5-8)
1. [ ] Add comparison view
2. [ ] Implement social sharing
3. [ ] Add more personas
4. [ ] Optimize performance
5. [ ] Launch MVP

---

## Resources

### External Services
- **NewsAPI:** https://newsapi.org/docs
- **OpenAI:** https://platform.openai.com/docs
- **Anthropic:** https://docs.anthropic.com

### Rails 8 Features
- **Solid Queue:** https://github.com/rails/solid_queue
- **Solid Cache:** https://github.com/rails/solid_cache
- **Kamal:** https://kamal-deploy.org

### Design Resources
- **Tailwind CSS:** https://tailwindcss.com/docs
- **Heroicons:** https://heroicons.com
- **Hotwire:** https://hotwired.dev

---

## Support & Contact

- **Documentation:** `/docs` folder
- **Issues:** GitHub Issues
- **Discussions:** GitHub Discussions

---

## License

[Your License Here]

