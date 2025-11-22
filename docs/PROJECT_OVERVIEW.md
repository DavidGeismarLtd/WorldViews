# Worldviews - Project Overview

## Ten-Line Explanation

1. **Worldviews** is a web app that shows how the same news can generate wildly different interpretations.
2. It pulls a factual global news item from a free API.
3. The news is fed into an LLM along with a "persona" prompt.
4. Each persona represents an exaggerated political or ideological worldview.
5. The LLM returns the persona's biased interpretation of the event.
6. Users can browse multiple personas for the same news story.
7. The goal is to reveal how narratives—not facts—shape opinions.
8. It's intentionally humorous, satirical, and self-aware.
9. No persona claims to be "correct"; all are deliberately caricatured.
10. The app aims to spark media literacy and critical thinking.

## Core Concept

Worldviews is a satirical media literacy tool that demonstrates how the same factual news event can be interpreted through radically different ideological lenses. By presenting exaggerated personas reacting to real news, the app reveals the role of bias, framing, and narrative in shaping public opinion.

## Key Features

### 1. News Aggregation
- Fetch daily global news from free news APIs (NewsAPI, GNews, etc.)
- Filter for significant, non-partisan factual events
- Store news items with metadata (headline, summary, source, date)

### 2. Persona System
- Curated collection of exaggerated ideological personas
- Each persona has a unique prompt template for LLM interpretation
- Personas are satirical caricatures, not real political positions
- Visual identity for each persona (avatar, color scheme, typography)

### 3. LLM Integration
- Send news + persona prompt to LLM (OpenAI, Anthropic, or local models)
- Generate biased interpretations in the persona's voice
- Cache interpretations to reduce API costs
- Fallback mechanisms for API failures

### 4. User Experience
- Browse news stories with multiple persona interpretations
- Swipe/toggle between different worldviews
- Side-by-side comparison view
- Share individual interpretations or comparisons
- Daily digest of top stories with all perspectives

### 5. Engagement Features
- "Guess the persona" game mode
- User voting on "most accurate caricature"
- Trending interpretations
- Social sharing optimized for virality

## Technical Stack

- **Backend**: Ruby on Rails 8.1
- **Database**: PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **LLM Integration**: OpenAI API / Anthropic Claude API
- **News API**: NewsAPI.org or GNews API
- **Caching**: Solid Cache (Rails 8)
- **Background Jobs**: Solid Queue (Rails 8)
- **Deployment**: Kamal (containerized deployment)

## Success Metrics

- Daily active users engaging with multiple personas
- Social shares and viral spread
- Time spent comparing different interpretations
- User-generated content (comments, persona suggestions)
- Media coverage and educational adoption

## Ethical Considerations

- Clear labeling as satire and parody
- Disclaimer that personas are exaggerated caricatures
- No targeting of specific individuals
- Focus on ideological frameworks, not personal attacks
- Educational framing around media literacy
- Transparent about AI-generated content
- **Phase 1:** No content moderation (fully automated)
- **Future:** May add filtering if issues arise

## Monetization

- **Phase 1 (MVP):** Completely free, no paywalls
- **Future considerations:**
  - Educational licensing for schools and universities
  - Sponsored personas (clearly labeled)
  - API access for researchers

## Roadmap

### Phase 1: MVP - US English (Weeks 1-4)
- Basic news fetching and storage (US news only)
- 6 core American-based personas
- LLM integration (GPT-4 primary, Claude fallback)
- On-demand interpretation generation
- Simple web interface with persona carousel
- Fully automated (no moderation/approval)
- Social sharing features

### Phase 2: Internationalization (Weeks 5-12)
- Multi-language support (Spanish, French, German, etc.)
- Country-specific personas (e.g., French personas for French news)
- Regional news sources
- Language detection and routing
- Localized UI

### Phase 3: Enhancement (Months 4-6)
- Comparison views
- "Guess the persona" game
- Advanced sharing (comparison images)
- Analytics dashboard
- Performance optimization

### Phase 4: Scale (Months 6+)
- User accounts (optional, for preferences)
- Community features
- Educational resources
- Custom persona suggestions
- API for third parties
