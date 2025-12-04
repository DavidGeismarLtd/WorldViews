# Twitter/X Integration Setup Guide

This guide will help you set up Twitter posting for your WorldViews personas.

## Overview

- **Strategy**: Top 3 personas post daily (Revolutionary, Tech Bro, Conspiracy Theorist)
- **API Tier**: Free tier (100 posts/month)
- **Usage**: ~90 posts/month (3 personas × 30 days)
- **Schedule**: Posts daily at 9am
- **Accounts**: 6 separate Twitter accounts (one per persona)

## Prerequisites

1. **Create 6 Twitter Accounts**
   - @worldviews_revolutionary (or similar)
   - @worldviews_techbro
   - @worldviews_conspiracy
   - @worldviews_centrist
   - @worldviews_doomer
   - @worldviews_optimist

2. **Get X API Access**
   - Go to https://developer.x.com
   - Apply for a developer account (free tier)
   - Create a new app
   - Get your API credentials

## Step 1: Configure Environment Variables

The main API credentials are already in your `.env` file:

```bash
X_API_KEY=FzBh4glcQkfe1YTXpTvgkvbfL
X_API_SECRET=6oBF2vCVgy1jBwm0QxoMziHXqHc0loPbffYmCTqpQBXB9Yrkzj
X_BEARER_TOKEN=AAAAAAAAAAAAAAAAAAAAAMPt5gEAAAAAXAwJisRTo4qIfpGCg%2BlvcxB47u8%3D9A4lg3r4xSfaV0tHa0v3dcZfTC23xS3vbmQiBO2by8H5eLrGrn
X_ACCESS_TOKEN=1487044713588961286-hYzX97WogWRswYlYdgythTUarxjGjL
X_ACCESS_TOKEN_SECRET=JhI2fLZ45FY49ggtowtnSBAwmMGmAujU54jaiflzulVdX
APP_HOST=worldviews.app
```

## Step 2: Set Up Each Persona

For each of your 6 Twitter accounts, you'll need to get separate access tokens.

### Getting Access Tokens for Each Account

1. Log into the Twitter account (e.g., @worldviews_revolutionary)
2. Go to https://developer.x.com/en/portal/dashboard
3. Select your app
4. Go to "Keys and tokens"
5. Generate "Access Token and Secret" for this account
6. Copy the access token and access token secret

### Configure Personas

Run the interactive setup:

```bash
rails twitter:setup
```

This will prompt you for each persona:
- Twitter handle (without @)
- Access token
- Access token secret

**OR** manually update in Rails console:

```ruby
persona = Persona.find_by(slug: 'revolutionary')
persona.update!(
  twitter_enabled: true,
  twitter_handle: 'worldviews_revolutionary',
  twitter_access_token: 'your-access-token-here',
  twitter_access_token_secret: 'your-access-token-secret-here'
)
```

Repeat for all 6 personas.

## Step 3: Test the Integration

Test posting a tweet for a specific persona:

```bash
rails twitter:test_post[revolutionary]
```

This will:
1. Get the latest featured story
2. Generate an interpretation (if needed)
3. Post a tweet
4. Show you the tweet URL

## Step 4: Verify Scheduled Job

The daily tweet job is configured in `config/recurring.yml`:

```yaml
post_daily_persona_tweets:
  class: PostDailyPersonaTweetJob
  schedule: every day at 9am
```

To manually run the daily job:

```bash
rails twitter:post_daily
```

## Monitoring

### Check Twitter Statistics

```bash
rails twitter:stats
```

This shows:
- Monthly API usage (X/100)
- Enabled personas
- Tweet counts per persona
- Recent tweets

### View Logs

All tweet attempts are logged in the `tweet_logs` table:

```ruby
# In Rails console
TweetLog.recent.limit(10).each do |log|
  puts "#{log.posted_at} - #{log.persona.name}: #{log.success ? '✅' : '❌'}"
  puts log.tweet_text
  puts log.error_message if log.error_message
  puts ""
end
```

## Tweet Format

Tweets follow this format:

```
[Emoji] [Hot take from interpretation]

[Link to story on worldviews.app]
```

Example:

```
✊ The billionaire class strikes again! This "innovation" is just another way to extract wealth from workers while pretending to solve problems they created.

https://worldviews.app/news_stories/123
```

## API Limits & Safety

- **Free tier**: 100 posts/month
- **Current usage**: 3 personas × 30 days = ~90 posts/month
- **Buffer**: 10 posts for testing/manual posts
- **Safety checks**:
  - Won't post if monthly limit reached
  - Each persona posts max once per day
  - Logs all attempts for monitoring

## Troubleshooting

### "Monthly tweet limit reached"

Check usage:
```bash
rails twitter:stats
```

Wait until next month or upgrade to Basic tier ($200/month for 15,000 posts).

### "Already tweeted today"

Each persona can only tweet once per day. This resets at midnight.

### OAuth errors

Verify credentials are correct:
```ruby
persona = Persona.find_by(slug: 'revolutionary')
puts persona.twitter_access_token
puts persona.twitter_access_token_secret
```

### No interpretations found

Generate interpretations first:
```bash
rails news:fetch_latest
```

## Going Viral 🚀

Tips for maximum engagement:

1. **Timing**: 9am is good for US East Coast. Adjust in `config/recurring.yml` if needed.
2. **Engagement**: Reply to comments from the persona accounts
3. **Cross-promotion**: Have personas quote-tweet each other
4. **Hashtags**: Consider adding trending hashtags (modify `XPosterService#build_tweet`)
5. **Images**: Add story images to tweets (future enhancement)

## Future Enhancements

- [ ] Add images to tweets
- [ ] Thread support (multi-tweet stories)
- [ ] Reply to mentions
- [ ] Analytics tracking (likes, retweets, etc.)
- [ ] A/B testing different tweet formats
- [ ] Upgrade to Basic tier for more posts

