# 📰 News Sync System Guide

## Overview

The Worldviews app uses a smart news synchronization system that:
- ✅ Fetches latest news from NewsAPI.org
- ✅ Prevents duplicates using unique `external_id` (MD5 hash of URL)
- ✅ Tracks what's new vs. updated vs. skipped
- ✅ Only generates interpretations for NEW stories (not duplicates)
- ✅ Supports multiple categories (general, technology, business, etc.)

---

## Quick Start

### Fetch Latest News (Recommended)

```bash
# Smart sync: fetches only new stories since last run
rails news:fetch_latest

# Or via background job
rails runner "FetchNewsJob.perform_now(mode: :latest)"
```

**What it does:**
1. Finds the most recent story's `published_at` timestamp
2. Fetches news from multiple categories (general, technology, business)
3. Filters to only articles newer than last fetch
4. Skips duplicates automatically
5. Queues interpretation generation for NEW stories only

---

## Usage Examples

### 1. Fetch Latest News (Smart Sync)

```bash
# Local development
rails news:fetch_latest

# Heroku
heroku run rails news:fetch_latest

# Fly.io
flyctl ssh console
./bin/rails news:fetch_latest
```

**Output:**
```
🔄 Fetching latest news...
📅 Last story published at: 2024-01-15 14:30:00 UTC

✅ Fetch complete!
   📊 12 new stories
   📊 3 updated stories
   📊 5 skipped (duplicates)

📰 Total stories in database: 45
```

### 2. Fetch Specific Category

```bash
# Fetch only technology news
rails news:fetch_category[technology]

# Fetch business news
rails news:fetch_category[business]
```

### 3. View Statistics

```bash
rails news:stats
```

**Output:**
```
📊 News Statistics
==================================================
Total stories: 45
Active stories: 42
Featured stories: 8

By category:
  general: 15
  technology: 18
  business: 12

Latest story: 2024-01-15 14:30:00 UTC
Oldest story: 2024-01-08 09:15:00 UTC

Stories with interpretations: 35
Total interpretations: 210
```

### 4. Test API Connection

```bash
rails news:test_api
```

---

## Background Job Usage

### Run Immediately

```ruby
# Smart sync (recommended)
FetchNewsJob.perform_now(mode: :latest)

# Single category
FetchNewsJob.perform_now(mode: :single_category, categories: ["technology"])
```

### Queue for Later (Sidekiq)

```ruby
# Smart sync
FetchNewsJob.perform_later(mode: :latest)

# Custom categories
FetchNewsJob.perform_later(
  mode: :latest,
  categories: %w[technology business science],
  limit_per_category: 30
)
```

---

## How Duplicate Prevention Works

### 1. External ID Generation

Each article gets a unique `external_id`:

```ruby
# Based on URL (preferred)
external_id = MD5(article_url)
# Example: "a3f5c8d9e2b1f4a6c7d8e9f0a1b2c3d4"

# Fallback: title + published date
external_id = MD5("#{title}-#{published_at}")
```

### 2. Find or Initialize

```ruby
story = NewsStory.find_or_initialize_by(external_id: external_id)

if story.new_record?
  # NEW story - save and queue interpretations
elsif story.headline != new_headline
  # UPDATED story - update but don't regenerate interpretations
else
  # DUPLICATE - skip entirely
end
```

### 3. Database Constraint

The `external_id` column has a unique index:

```ruby
add_index :news_stories, :external_id, unique: true
```

This prevents duplicates at the database level.

---

## Deployment Setup

### Heroku

```bash
# 1. Set API key
heroku config:set NEWS_API_KEY=your_newsapi_key_here

# 2. Initial fetch
heroku run rails news:fetch_latest

# 3. Schedule recurring fetches (using Heroku Scheduler add-on)
# Add this command to run every 6 hours:
rails news:fetch_latest
```

### Fly.io

```bash
# 1. Set API key
flyctl secrets set NEWS_API_KEY=your_newsapi_key_here

# 2. Initial fetch
flyctl ssh console
./bin/rails news:fetch_latest
```

---

## API Key Management

### Get a NewsAPI Key

1. Go to https://newsapi.org/register
2. Free tier: 100 requests/day
3. Copy your API key

### Set Environment Variable

```bash
# Local (.env file)
NEWS_API_KEY=your_key_here

# Heroku
heroku config:set NEWS_API_KEY=your_key_here

# Fly.io
flyctl secrets set NEWS_API_KEY=your_key_here
```

### Test Connection

```bash
rails news:test_api
```

---

## Troubleshooting

### "NEWS_API_KEY is not set"

**Problem:** API key missing or blank

**Solution:**
```bash
# Check if set
echo $NEWS_API_KEY

# Set it
export NEWS_API_KEY=your_key_here

# Or add to .env file
echo "NEWS_API_KEY=your_key_here" >> .env
```

### No New Stories Fetched

**Problem:** All stories are older than last fetch

**Solution:** This is normal! It means you're up to date.

```bash
# Check last fetch time
rails runner "puts NewsStory.maximum(:published_at)"

# Force fetch anyway (will skip duplicates)
rails news:fetch_latest
```

### Duplicate Stories

**Problem:** Same story appearing multiple times

**Solution:** This shouldn't happen due to unique constraint, but if it does:

```ruby
# Find duplicates
NewsStory.group(:source_url).having("count(*) > 1").count

# Clean up (in rails console)
NewsStory.find_each do |story|
  duplicates = NewsStory.where(source_url: story.source_url).where.not(id: story.id)
  duplicates.destroy_all if duplicates.any?
end
```

---

## Best Practices

1. **Use `:latest` mode** for regular syncs (smart, efficient)
2. **Run every 6 hours** to stay current without hitting API limits
3. **Monitor API usage** (100 requests/day on free tier)
4. **Archive old stories** after 30 days to keep database lean

```bash
# Archive old stories
rails news:cleanup_old
```

---

## Next Steps

- Set up recurring job (Heroku Scheduler or cron)
- Monitor API usage
- Consider upgrading NewsAPI plan if needed (500 requests/day = $449/month)

