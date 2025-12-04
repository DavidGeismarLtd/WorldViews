# Twitter Integration - Quick Reference

## 🚀 Quick Start

```bash
# 1. Setup personas with Twitter credentials
rails twitter:setup

# 2. Test posting for a persona
rails twitter:test_post[revolutionary]

# 3. Check statistics
rails twitter:stats

# 4. Manually run daily job
rails twitter:post_daily
```

## 📋 Rake Commands

| Command | Description |
|---------|-------------|
| `rails twitter:setup` | Interactive setup wizard for configuring personas |
| `rails twitter:test_post[slug]` | Test posting a tweet for a specific persona |
| `rails twitter:stats` | View API usage and tweet statistics |
| `rails twitter:post_daily` | Manually trigger the daily tweet job |

## 🎯 Top 3 Personas (Post Daily)

| Persona | Slug | Emoji | Twitter Handle |
|---------|------|-------|----------------|
| Revolutionary | `revolutionary` | ✊ | @worldviews_revolutionary |
| Tech Bro | `tech-bro` | 🚀 | @worldviews_techbro |
| Conspiracy Theorist | `conspiracy-theorist` | 👁️ | @worldviews_conspiracy |

## 📊 API Limits

- **Free Tier**: 100 posts/month
- **Daily Usage**: 3 posts/day (one per top persona)
- **Monthly Usage**: ~90 posts/month
- **Buffer**: 10 posts for testing

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `.env` | X API credentials |
| `config/recurring.yml` | Daily job schedule (9am) |
| `app/services/x_poster_service.rb` | Tweet posting logic |
| `app/jobs/post_daily_persona_tweet_job.rb` | Daily automation |

## 💾 Database Tables

### personas
```ruby
twitter_handle              # @username
twitter_enabled             # true/false
last_tweet_at              # timestamp
twitter_access_token       # OAuth token
twitter_access_token_secret # OAuth secret
```

### tweet_logs
```ruby
persona_id      # which persona
news_story_id   # which story
tweet_id        # Twitter's ID
tweet_text      # full tweet content
posted_at       # when posted
success         # true/false
error_message   # if failed
```

## 🔍 Monitoring in Rails Console

```ruby
# Check API usage
TweetLog.monthly_count        # => 45
TweetLog.remaining_this_month # => 55

# Check persona status
Persona.twitter_enabled.count # => 6
Persona.find_by(slug: 'revolutionary').can_tweet_today? # => true

# View recent tweets
TweetLog.successful.recent.limit(5).each do |log|
  puts "#{log.persona.name}: #{log.tweet_text[0..50]}..."
end

# Check last tweet for a persona
persona = Persona.find_by(slug: 'revolutionary')
persona.last_tweet_at         # => 2024-11-30 09:00:00
persona.tweets_this_month     # => 15
```

## 🐛 Troubleshooting

### Problem: "Monthly tweet limit reached"
```ruby
# Check usage
TweetLog.monthly_count # If >= 100, wait until next month
```

### Problem: "Already tweeted today"
```ruby
# Check last tweet time
persona = Persona.find_by(slug: 'revolutionary')
persona.last_tweet_at # Must be > 24 hours ago
```

### Problem: OAuth errors
```ruby
# Verify credentials
persona = Persona.find_by(slug: 'revolutionary')
persona.has_twitter_credentials? # Should be true
persona.twitter_access_token.present? # Should be true
```

### Problem: No interpretations
```bash
# Fetch news and generate interpretations
rails news:fetch_latest
```

## 📝 Manual Operations

### Enable Twitter for a persona
```ruby
persona = Persona.find_by(slug: 'revolutionary')
persona.update!(
  twitter_enabled: true,
  twitter_handle: 'worldviews_revolutionary',
  twitter_access_token: 'your-token',
  twitter_access_token_secret: 'your-secret'
)
```

### Disable Twitter for a persona
```ruby
persona = Persona.find_by(slug: 'revolutionary')
persona.update!(twitter_enabled: false)
```

### Reset last_tweet_at (allow immediate retweet)
```ruby
persona = Persona.find_by(slug: 'revolutionary')
persona.update!(last_tweet_at: nil)
```

### View failed tweets
```ruby
TweetLog.failed.recent.each do |log|
  puts "#{log.persona.name} - #{log.error_message}"
end
```

## 🎨 Tweet Format

```
[Emoji] [Truncated interpretation]

[Link to story]
```

**Character limits:**
- Total: 280 characters
- URL: 23 characters (Twitter's t.co shortener)
- Emoji + spacing: ~5 characters
- Available for content: ~240 characters

## ⏰ Schedule

- **Job**: `PostDailyPersonaTweetJob`
- **Schedule**: Every day at 9:00 AM
- **Configured in**: `config/recurring.yml`

## 🔐 Environment Variables

```bash
X_API_KEY                 # App API key
X_API_SECRET              # App API secret
X_BEARER_TOKEN            # App bearer token
X_ACCESS_TOKEN            # Default access token
X_ACCESS_TOKEN_SECRET     # Default access token secret
APP_HOST                  # worldviews.app
```

## 📈 Success Metrics to Track

1. **Engagement**: Likes, retweets, replies per tweet
2. **Click-through**: Traffic from Twitter to worldviews.app
3. **Follower growth**: Per persona account
4. **Viral tweets**: Which personas/topics get most engagement
5. **API efficiency**: Staying within 100/month limit

## 🎯 Next Steps After Setup

1. ✅ Create 6 Twitter accounts
2. ✅ Get API credentials for each
3. ✅ Run `rails twitter:setup`
4. ✅ Test with `rails twitter:test_post[revolutionary]`
5. ✅ Monitor with `rails twitter:stats`
6. ✅ Let it run automatically at 9am daily
7. 📊 Track engagement and iterate

