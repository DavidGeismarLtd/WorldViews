# 📰 News Sync Flow Diagram

## Smart Sync Process

```
┌─────────────────────────────────────────────────────────────┐
│                    FetchNewsJob.perform                      │
│                     (mode: :latest)                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              NewsFetcherService.fetch_latest_news            │
│                                                              │
│  1. Get last fetch time:                                    │
│     last_fetch = NewsStory.maximum(:published_at)           │
│     # Example: 2024-01-15 14:30:00 UTC                      │
│                                                              │
│  2. For each category (general, technology, business):      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  NewsAPI.org API Call                        │
│                                                              │
│  GET /v2/top-headlines                                      │
│  ?apiKey=xxx                                                │
│  &country=us                                                │
│  &category=general                                          │
│  &pageSize=20                                               │
│                                                              │
│  Returns: 20 articles                                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Filter New Articles                       │
│                                                              │
│  articles.select do |article|                               │
│    article.published_at > last_fetch                        │
│  end                                                         │
│                                                              │
│  Example: 20 total → 8 new                                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Process Each Article (8 new ones)               │
│                                                              │
│  For each article:                                          │
│    1. Generate external_id = MD5(article.url)              │
│    2. Find or initialize story by external_id              │
│    3. Check status:                                         │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    ┌────────┐     ┌─────────┐     ┌─────────┐
    │  NEW   │     │ UPDATED │     │ SKIPPED │
    │ STORY  │     │  STORY  │     │  STORY  │
    └───┬────┘     └────┬────┘     └────┬────┘
        │               │               │
        ▼               ▼               │
   Save to DB      Update DB            │
        │               │               │
        ▼               │               │
   Queue Job           │               │
   (Generate           │               │
   Interpretations)    │               │
        │               │               │
        └───────────────┴───────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Return Statistics                         │
│                                                              │
│  {                                                           │
│    new: [story1, story2, ...],      # 5 stories             │
│    updated: [story3],                # 1 story              │
│    skipped: [story4, story5],        # 2 stories            │
│    total: 8                                                  │
│  }                                                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Log Results                               │
│                                                              │
│  ✅ FetchNewsJob complete:                                  │
│     📊 5 new stories                                        │
│     📊 1 updated stories                                    │
│     📊 2 skipped (duplicates)                               │
│     🤖 Queued interpretation generation for 5 new stories   │
└─────────────────────────────────────────────────────────────┘
```

---

## Duplicate Detection Logic

```
Article from NewsAPI
        │
        ▼
Generate external_id = MD5(url)
        │
        ▼
Find story by external_id
        │
        ├─── Not found? ──────────────────┐
        │                                  │
        │                                  ▼
        │                            NEW STORY
        │                                  │
        │                                  ▼
        │                            Save to database
        │                                  │
        │                                  ▼
        │                            Queue interpretations
        │
        ├─── Found + headline changed? ───┐
        │                                  │
        │                                  ▼
        │                            UPDATED STORY
        │                                  │
        │                                  ▼
        │                            Update database
        │                                  │
        │                                  ▼
        │                            Don't queue interpretations
        │
        └─── Found + unchanged? ──────────┐
                                          │
                                          ▼
                                    SKIPPED STORY
                                          │
                                          ▼
                                    Do nothing
```

---

## Database Uniqueness Guarantee

```sql
-- Schema
CREATE TABLE news_stories (
  id SERIAL PRIMARY KEY,
  external_id VARCHAR NOT NULL,
  headline VARCHAR NOT NULL,
  published_at TIMESTAMP,
  ...
);

-- Unique constraint
CREATE UNIQUE INDEX index_news_stories_on_external_id 
ON news_stories (external_id);

-- Result: Duplicate INSERT will fail
INSERT INTO news_stories (external_id, headline, ...)
VALUES ('a3f5c8d9...', 'Same Article', ...);
-- ERROR: duplicate key value violates unique constraint
```

---

## Example Timeline

```
Day 1, 9:00 AM - First Fetch
├─ Fetch 20 articles from NewsAPI
├─ All 20 are NEW (database empty)
├─ Save all 20 to database
└─ Queue 20 interpretation jobs

Day 1, 3:00 PM - Second Fetch (6 hours later)
├─ Last fetch: 9:00 AM
├─ Fetch 20 articles from NewsAPI
├─ Filter: only 8 published after 9:00 AM
├─ Process 8 articles:
│   ├─ 5 NEW (save + queue interpretations)
│   ├─ 2 SKIPPED (already in database)
│   └─ 1 UPDATED (headline changed, update only)
└─ Total in database: 25 stories

Day 1, 9:00 PM - Third Fetch (6 hours later)
├─ Last fetch: 3:00 PM
├─ Fetch 20 articles from NewsAPI
├─ Filter: only 3 published after 3:00 PM
├─ Process 3 articles:
│   ├─ 3 NEW (save + queue interpretations)
│   ├─ 0 SKIPPED
│   └─ 0 UPDATED
└─ Total in database: 28 stories
```

---

## API Request Optimization

```
Traditional Approach (Wasteful):
├─ Fetch all 20 articles
├─ Process all 20 articles
├─ Database checks for duplicates
└─ Result: Wasted processing on duplicates

Smart Sync Approach (Efficient):
├─ Fetch all 20 articles
├─ Filter to only NEW articles (8 articles)
├─ Process only 8 articles
└─ Result: 60% less processing!
```

---

## Interpretation Generation Strategy

```
NEW Story
├─ Generate interpretations for all 6 personas
├─ Queue 6 background jobs
└─ User sees fresh content

UPDATED Story
├─ Keep existing interpretations
├─ Don't regenerate (saves API costs)
└─ User sees cached content

SKIPPED Story
├─ Already has interpretations
├─ Do nothing
└─ User sees cached content
```

**Why?** Interpretations are expensive (OpenAI API calls). Only generate for truly new content.

---

## Cost Analysis

### Without Smart Sync
```
4 fetches/day × 20 articles = 80 articles processed
80 articles × 6 personas = 480 interpretation jobs
480 jobs × $0.002 (GPT-4 cost) = $0.96/day
$0.96 × 30 days = $28.80/month
```

### With Smart Sync
```
4 fetches/day × 8 new articles = 32 articles processed
32 articles × 6 personas = 192 interpretation jobs
192 jobs × $0.002 (GPT-4 cost) = $0.38/day
$0.38 × 30 days = $11.40/month
```

**Savings: $17.40/month (60% reduction)** 💰

