# Worldviews - Implementation Plan

## Development Phases

### Phase 1: MVP Foundation (Weeks 1-4)

**Goal:** Launch a functional prototype with core features

#### Week 1: Setup & Infrastructure
- [x] Initialize Rails 8.1 application
- [ ] Set up PostgreSQL database
- [ ] Configure Tailwind CSS
- [ ] Set up development environment
- [ ] Create basic routing structure
- [ ] Set up version control and CI/CD

**Deliverables:**
- Working Rails app
- Database configured
- Basic homepage rendering

---

#### Week 2: Core Models & Data Layer

**Tasks:**
1. **Create Database Schema**
   ```bash
   rails generate model NewsStory external_id:string headline:string summary:text \
     source:string source_url:string published_at:datetime category:string \
     image_url:string featured:boolean active:boolean metadata:jsonb
   
   rails generate model Persona name:string slug:string description:text \
     system_prompt:text avatar_url:string color_primary:string \
     color_secondary:string display_order:integer active:boolean
   
   rails generate model Interpretation news_story:references persona:references \
     content:text llm_model:string llm_tokens_used:integer \
     generation_time_ms:integer cached:boolean metadata:jsonb
   ```

2. **Add Validations & Associations**
   - NewsStory: validates presence of headline, source
   - Persona: validates uniqueness of slug
   - Interpretation: validates uniqueness of [news_story_id, persona_id]

3. **Create Seed Data**
   - 6 core personas with prompts
   - 3-5 sample news stories
   - Pre-generated interpretations for testing

**Deliverables:**
- Database migrations run successfully
- Models with validations
- Seed data populated

---

#### Week 3: External Integrations

**Tasks:**
1. **News API Integration**
   ```ruby
   # app/services/news_fetcher_service.rb
   class NewsFetcherService
     def initialize(api_key: ENV['NEWS_API_KEY'])
       @api_key = api_key
       @base_url = 'https://newsapi.org/v2'
     end
     
     def fetch_top_headlines(category: 'general', limit: 10)
       # Implementation
     end
   end
   ```

2. **LLM API Integration**
   ```ruby
   # app/services/llm_client_service.rb
   class LlmClientService
     def initialize
       @openai_client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
     end
     
     def generate_interpretation(news_summary:, persona_prompt:, max_tokens: 500)
       # Implementation with caching
     end
   end
   ```

3. **Background Jobs**
   ```ruby
   # app/jobs/fetch_news_job.rb
   class FetchNewsJob < ApplicationJob
     queue_as :default
     
     def perform
       NewsFetcherService.new.fetch_and_store_news
     end
   end
   
   # app/jobs/generate_interpretations_job.rb
   class GenerateInterpretationsJob < ApplicationJob
     queue_as :default
     
     def perform(news_story_id)
       # Generate interpretations for all active personas
     end
   end
   ```

**Deliverables:**
- News fetching working
- LLM integration functional
- Background jobs processing

---

#### Week 4: Basic UI & Controllers

**Tasks:**
1. **Controllers**
   ```ruby
   # app/controllers/news_stories_controller.rb
   class NewsStoriesController < ApplicationController
     def index
       @news_stories = NewsStory.active.recent.limit(10)
     end
     
     def show
       @news_story = NewsStory.find(params[:id])
       @interpretations = @news_story.interpretations.includes(:persona)
     end
   end
   ```

2. **Views (Hotwire/Turbo)**
   ```erb
   <!-- app/views/news_stories/index.html.erb -->
   <div class="container mx-auto px-4">
     <h1 class="text-4xl font-bold mb-8">Today's Stories</h1>
     
     <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
       <%= render @news_stories %>
     </div>
   </div>
   
   <!-- app/views/news_stories/_news_story.html.erb -->
   <div class="bg-white rounded-lg shadow-md p-6">
     <h2 class="text-2xl font-bold mb-2"><%= news_story.headline %></h2>
     <p class="text-gray-600 mb-4"><%= news_story.summary %></p>
     <%= link_to "See All Perspectives", news_story_path(news_story), 
         class: "btn btn-primary" %>
   </div>
   ```

3. **Stimulus Controllers for Interactivity**
   ```javascript
   // app/javascript/controllers/persona_carousel_controller.js
   import { Controller } from "@hotwired/stimulus"
   
   export default class extends Controller {
     static targets = ["slide", "indicator"]
     
     connect() {
       this.index = 0
       this.showSlide(this.index)
     }
     
     next() {
       this.index = (this.index + 1) % this.slideTargets.length
       this.showSlide(this.index)
     }
     
     previous() {
       this.index = (this.index - 1 + this.slideTargets.length) % this.slideTargets.length
       this.showSlide(this.index)
     }
     
     showSlide(index) {
       // Implementation
     }
   }
   ```

**Deliverables:**
- Homepage listing stories
- Story detail page with persona carousel
- Basic styling with Tailwind
- Swipe/click navigation working

---

### Phase 2: Enhancement & Polish (Weeks 5-8)

#### Week 5: Advanced UI Features

**Tasks:**
- Comparison view (side-by-side personas)
- Share functionality (social media cards)
- Reaction buttons (emoji reactions)
- Mobile swipe gestures
- Loading states and animations

**Components to Build:**
- `PersonaCard` component
- `ComparisonGrid` component
- `ShareModal` component
- `ReactionButton` component

---

#### Week 6: Caching & Performance

**Tasks:**
- Implement multi-level caching strategy
- Add database indexes
- Optimize N+1 queries
- Set up CDN for assets
- Implement lazy loading
- Add service worker for offline support

**Performance Targets:**
- Homepage load: < 2 seconds
- Story detail: < 1 second
- Persona switch: < 300ms
- LLM response: < 5 seconds (cached: instant)

---

#### Week 7: Additional Personas & Content

**Tasks:**
- Add 4-6 more personas
- Refine persona prompts based on testing
- Create persona avatar illustrations
- Build persona directory page
- Add persona filtering/selection

**New Personas:**
- The Environmentalist
- The Libertarian
- The Social Justice Advocate
- The Academic

---

#### Week 8: Social Features & Sharing

**Tasks:**
- Share image generation service
- Open Graph meta tags
- Twitter Card optimization
- Copy-to-clipboard functionality
- Share tracking analytics
- Viral loop optimization

---

### Phase 3: User Engagement (Weeks 9-12)

#### Week 9: User Accounts

**Tasks:**
- Add Devise for authentication
- User registration/login
- User preferences (favorite personas)
- Reading history
- Bookmarking stories

---

#### Week 10: Gamification

**Tasks:**
- "Guess the Persona" game mode
- Scoring system
- Leaderboards
- Daily challenges
- Achievement badges

---

#### Week 11: Community Features

**Tasks:**
- User comments on interpretations
- Voting on interpretation quality
- User-suggested personas
- Moderation tools
- Reporting system

---

#### Week 12: Analytics & Optimization

**Tasks:**
- Google Analytics integration
- Custom event tracking
- A/B testing framework
- Conversion funnel analysis
- Performance monitoring
- Error tracking (Sentry)

---

## Technical Implementation Details

### Environment Variables

```bash
# .env.example
NEWS_API_KEY=your_newsapi_key
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key (backup)
DATABASE_URL=postgresql://localhost/worldviews_development
REDIS_URL=redis://localhost:6379/0
AWS_ACCESS_KEY_ID=your_aws_key (for S3)
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_REGION=us-east-1
AWS_BUCKET=worldviews-assets
```

### Gem Dependencies

```ruby
# Gemfile additions
gem 'httparty'           # HTTP requests
gem 'ruby-openai'        # OpenAI API client
gem 'anthropic'          # Anthropic API client
gem 'devise'             # Authentication (Phase 3)
gem 'pundit'             # Authorization (Phase 3)
gem 'pagy'               # Pagination
gem 'image_processing'   # Image manipulation
gem 'aws-sdk-s3'         # S3 storage
gem 'sidekiq'            # Background jobs (if not using Solid Queue)

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'vcr'              # Record HTTP interactions
  gem 'webmock'          # Stub HTTP requests
end
```

### Scheduled Jobs

```ruby
# config/recurring.yml
production:
  fetch_news:
    class: FetchNewsJob
    schedule: "every 6 hours"
  
  generate_interpretations:
    class: GenerateInterpretationsJob
    schedule: "every 30 minutes"
  
  cleanup_old_stories:
    class: CleanupOldStoriesJob
    schedule: "every day at 3am"
```

---

## Testing Strategy

### Unit Tests
- Model validations
- Service object logic
- Helper methods

### Integration Tests
- API integrations (with VCR)
- Background job processing
- Email delivery

### System Tests
- User flows (Capybara)
- JavaScript interactions
- Mobile responsiveness

### Test Coverage Goal
- Minimum 80% coverage
- 100% coverage for critical paths

---

## Deployment Strategy

### Staging Environment
- Deploy to staging after each PR merge
- Run full test suite
- Manual QA testing
- Smoke tests

### Production Deployment
- Weekly releases (Fridays)
- Blue-green deployment
- Database migrations run first
- Rollback plan ready
- Monitor error rates

### Monitoring
- Uptime monitoring (UptimeRobot)
- Error tracking (Sentry)
- Performance monitoring (Scout APM)
- Log aggregation (Papertrail)

---

## Success Metrics

### Week 4 (MVP Launch)
- [ ] 3 news stories fetched daily
- [ ] 6 personas generating interpretations
- [ ] Homepage loads in < 2 seconds
- [ ] Zero critical bugs

### Week 8 (Enhanced Version)
- [ ] 10+ personas active
- [ ] 100+ daily visitors
- [ ] 50+ social shares per week
- [ ] < 5% error rate

### Week 12 (Full Launch)
- [ ] 1,000+ daily active users
- [ ] 500+ social shares per week
- [ ] 10+ user-generated persona suggestions
- [ ] Featured in 1+ tech publication

