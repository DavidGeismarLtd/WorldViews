# Worldviews - MVP Decisions & Configuration

## Project Decisions (Confirmed)

### 1. Content Strategy
- ✅ **Fully automated** - No manual approval or moderation
- ✅ **No content filtering** - Trust LLM outputs (can add later if needed)
- ✅ **US news only** - Focus on American news sources initially
- ✅ **All categories** - Don't avoid any news topics
- ✅ **English only** - Phase 1 is US English

### 2. LLM Strategy
- ✅ **On-demand generation** - Generate interpretations when requested (not pre-generated)
- ✅ **GPT-4 primary** - Use `gpt-4-turbo-preview` for quality
- ✅ **Claude fallback** - If OpenAI fails, use Anthropic Claude
- ✅ **Aggressive caching** - Cache all interpretations indefinitely
- ✅ **No budget constraints** - Use best models for quality

### 3. Personas
- ✅ **6 core American personas** for MVP:
  1. The Revolutionary (Hardcore Leftist)
  2. The Moderate (Smug Centrist)
  3. The Patriot (Conservative Nationalist)
  4. The Skeptic (Conspiracy Theorist)
  5. The Disruptor (Tech Bro)
  6. The Burnt Out (Exhausted Millennial/Gen-Z)
- ✅ **All personas approved** - No sensitivity concerns
- ✅ **Exaggerated but not offensive** - Satirical caricatures

### 4. Monetization
- ✅ **100% Free** - No paywalls, no limits, no premium tiers
- ✅ **No user accounts required** - Anonymous browsing
- ✅ **Future:** May add optional accounts for preferences

### 5. Branding
- ✅ **Tagline:** "The news, seen through everyone's delusions"
- ✅ **No existing assets** - Design from scratch
- ✅ **No domain yet** - Will deploy to temporary domain initially
- ✅ **Playful, satirical tone** - Self-aware humor

### 6. Internationalization (Phase 2)
- 🔜 **Multi-language support** - Spanish, French, German, etc.
- 🔜 **Country-specific personas** - French personas for French news, etc.
- 🔜 **Regional news sources** - Localized news APIs
- 🔜 **Language routing** - Auto-detect or user selection

---

## Technical Configuration

### News API
```yaml
Provider: NewsAPI.org
Endpoint: /v2/top-headlines
Country: US
Categories: 
  - general
  - business
  - technology
  - politics
  - science
Fetch Frequency: Every 6 hours
Stories per Fetch: 10
```

### LLM Configuration
```yaml
Primary:
  Provider: OpenAI
  Model: gpt-4-turbo-preview
  Max Tokens: 500
  Temperature: 0.8
  Frequency Penalty: 0.3
  Presence Penalty: 0.3

Fallback:
  Provider: Anthropic
  Model: claude-3-sonnet-20240229
  Max Tokens: 500
  Temperature: 0.8

Caching:
  Strategy: Cache all interpretations
  TTL: Indefinite (30 days for safety)
  Key Format: "interpretation/#{news_story_id}/#{persona_id}/v1"
```

### Generation Strategy
```yaml
Trigger: On-demand (when user views story)
Process:
  1. User requests story detail page
  2. Check cache for existing interpretations
  3. If missing, generate on-the-fly
  4. Show loading state while generating
  5. Cache result immediately
  6. Display to user

Background Jobs:
  - Fetch news every 6 hours
  - Pre-generate interpretations for featured stories (optional)
  - Cleanup old stories after 30 days
```

---

## MVP Feature Checklist

### Core Features (Must Have)
- [ ] News fetching from NewsAPI
- [ ] 6 personas with system prompts
- [ ] LLM integration (OpenAI + Anthropic fallback)
- [ ] On-demand interpretation generation
- [ ] Caching layer
- [ ] Homepage with story grid
- [ ] Story detail page
- [ ] Persona carousel (swipe/click)
- [ ] Mobile-responsive design
- [ ] Social sharing (basic)

### Nice to Have (Phase 1)
- [ ] Comparison view (side-by-side)
- [ ] Share image generation
- [ ] Reaction buttons (emoji)
- [ ] Loading animations
- [ ] Error handling UI

### Deferred to Phase 2
- [ ] User accounts
- [ ] Multi-language support
- [ ] Country-specific personas
- [ ] "Guess the persona" game
- [ ] Comments/community features
- [ ] Analytics dashboard

---

## Development Priorities

### Week 1: Foundation
1. Database schema (NewsStory, Persona, Interpretation)
2. Seed data (6 personas)
3. News API integration
4. LLM service with fallback

### Week 2: Core Logic
1. Interpretation generation service
2. Caching strategy
3. Background jobs
4. Error handling

### Week 3: UI/UX
1. Homepage layout
2. Story detail page
3. Persona carousel
4. Mobile responsiveness
5. Tailwind styling

### Week 4: Polish & Launch
1. Social sharing
2. Performance optimization
3. Testing
4. Deployment
5. Soft launch

---

## Environment Variables Needed

```bash
# Required for MVP
NEWS_API_KEY=xxx                    # From newsapi.org
OPENAI_API_KEY=xxx                  # From platform.openai.com
ANTHROPIC_API_KEY=xxx               # From console.anthropic.com

# Database
DATABASE_URL=postgresql://...

# Optional
RAILS_ENV=development
RAILS_LOG_LEVEL=info
```

---

## Success Metrics (MVP)

### Technical
- [ ] News fetched successfully every 6 hours
- [ ] 95%+ LLM generation success rate
- [ ] < 5 second interpretation generation time
- [ ] 99%+ cache hit rate after initial generation
- [ ] Zero critical bugs

### User Experience
- [ ] Homepage loads in < 2 seconds
- [ ] Story detail loads in < 3 seconds
- [ ] Smooth persona switching (< 300ms)
- [ ] Mobile-friendly (responsive design)
- [ ] Shareable on social media

### Content
- [ ] 10+ news stories available daily
- [ ] All 6 personas generating quality interpretations
- [ ] Interpretations are funny and recognizable
- [ ] No offensive or broken outputs

---

## Launch Checklist

- [ ] All environment variables configured
- [ ] Database migrations run
- [ ] Seed data loaded (6 personas)
- [ ] News API tested and working
- [ ] LLM API tested (both OpenAI and Claude)
- [ ] Caching verified
- [ ] Background jobs running
- [ ] UI tested on mobile and desktop
- [ ] Social sharing tested
- [ ] Error pages styled
- [ ] Deployment successful
- [ ] Domain configured (or using temporary)
- [ ] SSL certificate active
- [ ] Monitoring set up
- [ ] Soft launch to friends/family
- [ ] Gather feedback
- [ ] Public launch 🚀

