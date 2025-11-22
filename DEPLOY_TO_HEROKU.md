# 🚀 Deploy to Heroku - Complete Checklist

## Pre-Deployment Checklist

- [x] Redis SSL fix implemented
- [x] Smart news sync system implemented
- [x] Auto-featured stories implemented
- [x] All tests passing (42 specs)
- [ ] Environment variables set on Heroku
- [ ] Database cleaned of mock data
- [ ] Real news fetched

---

## Step 1: Commit and Push Changes

```bash
# Check what's changed
git status

# Add all changes
git add .

# Commit
git commit -m "Add smart news sync, auto-featured stories, and fix Redis SSL"

# Push to Heroku
git push heroku master
```

**Expected output:**
```
remote: -----> Building on the Heroku-22 stack
remote: -----> Using buildpack: heroku/ruby
remote: -----> Ruby app detected
remote: -----> Installing dependencies using bundler 2.x
remote: -----> Detecting rake tasks
remote: -----> Precompiling assets
remote: -----> Build succeeded!
remote: -----> Launching...
remote:        Released v42
```

---

## Step 2: Verify Environment Variables

```bash
# Check all config vars
heroku config

# Should see:
# REDIS_URL:         rediss://...
# DATABASE_URL:      postgres://...
# RAILS_MASTER_KEY:  ...
# NEWS_API_KEY:      ... (if set)
# OPENAI_API_KEY:    ... (if set)
```

### Set Missing Variables

```bash
# If NEWS_API_KEY is missing
heroku config:set NEWS_API_KEY=your_newsapi_key_here

# If OPENAI_API_KEY is missing
heroku config:set OPENAI_API_KEY=your_openai_key_here

# If ANTHROPIC_API_KEY is missing (optional, for Claude fallback)
heroku config:set ANTHROPIC_API_KEY=your_anthropic_key_here
```

---

## Step 3: Run Database Migrations

```bash
# Run migrations (if any)
heroku run rails db:migrate

# Check database status
heroku run rails db:version
```

---

## Step 4: Clean Up Mock Data

```bash
# Open Rails console
heroku run rails console

# In the console:
> NewsStory.count
# => Shows current count (probably has mock data)

> NewsStory.destroy_all
# => Deletes all stories

> Interpretation.destroy_all
# => Deletes all interpretations

> NewsStory.count
# => 0

> exit
```

---

## Step 5: Seed Personas

```bash
# Run seeds to create personas
heroku run rails db:seed

# Verify personas were created
heroku run rails console
> Persona.count
# => 6

> Persona.pluck(:name)
# => ["The Revolutionary", "The Moderate", "The Patriot", "The Skeptic", "The Disruptor", "The Burnt Out"]

> exit
```

---

## Step 6: Test Redis Connection

```bash
# Open Rails console
heroku run rails console

# Test cache
> Rails.cache.write("test", "Hello from Heroku!")
# => true

> Rails.cache.read("test")
# => "Hello from Heroku!"

# Test Redis directly
> redis = Redis.new(url: ENV["REDIS_URL"], ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
> redis.ping
# => "PONG"

> exit
```

**If this fails**, check `REDIS_SSL_FIX.md` for troubleshooting.

---

## Step 7: Fetch Real News

```bash
# Test NewsAPI connection first
heroku run rails news:test_api

# Expected output:
# 🔍 Testing NewsAPI connection...
# ✅ API key found: 55c501f2c1...
# Fetching test headlines...
# ✅ Successfully fetched 5 articles:
#   • [Article headline 1]
#   • [Article headline 2]
#   • [Article headline 3]

# Fetch latest news
heroku run rails news:fetch_latest

# Expected output:
# 🔄 Fetching latest news...
# 📅 Last story published at: Never
# 
#   📂 Category: general
#   📊 Found 20 new articles (out of 20 total)
#   ✓ NEW: [Article headline]...
#   
# ✅ Fetch complete!
#    📊 45 new stories
#    📊 0 updated stories
#    📊 0 skipped (duplicates)
#    🤖 Queued interpretation generation for 45 new stories
```

---

## Step 8: Verify Featured Stories

```bash
# Check featured stories
heroku run rails console

> NewsStory.featured.count
# => 3

> NewsStory.featured.order(published_at: :desc).pluck(:headline, :published_at)
# => [["Most recent headline", 2024-01-15 14:30:00 UTC],
#     ["Second most recent", 2024-01-15 13:45:00 UTC],
#     ["Third most recent", 2024-01-15 12:20:00 UTC]]

> exit
```

---

## Step 9: Scale Dynos

```bash
# Check current dyno status
heroku ps

# Scale web dyno (should already be running)
heroku ps:scale web=1

# Scale worker dyno for Sidekiq (IMPORTANT!)
heroku ps:scale worker=1

# Verify
heroku ps
# => web.1: up 2024/01/15 14:30:00
# => worker.1: up 2024/01/15 14:30:00
```

---

## Step 10: Monitor Logs

```bash
# Watch logs in real-time
heroku logs --tail

# Look for:
# ✅ "Started GET" requests
# ✅ "Completed 200 OK"
# ✅ Sidekiq job processing
# ✅ Interpretation generation
# ❌ NO Redis SSL errors
# ❌ NO 500 errors
```

---

## Step 11: Test the App

```bash
# Open the app
heroku open
```

### Manual Testing Checklist

1. **Homepage**
   - [ ] Shows news stories
   - [ ] Shows 3 featured stories at top
   - [ ] Stories have images and headlines

2. **Story Detail Page**
   - [ ] Click on a story
   - [ ] See persona carousel
   - [ ] Click on a persona
   - [ ] See "thinking hard..." loading state
   - [ ] Interpretation loads successfully
   - [ ] No 500 errors

3. **Persona Navigation**
   - [ ] Swipe left/right works
   - [ ] Click persona avatars works
   - [ ] All 6 personas load

4. **Featured Stories**
   - [ ] Homepage shows 3 featured stories
   - [ ] They are the 3 most recent

---

## Step 12: Set Up Recurring News Fetch

### Option A: Heroku Scheduler (Recommended)

```bash
# Add Heroku Scheduler add-on (free tier available)
heroku addons:create scheduler:standard

# Open scheduler dashboard
heroku addons:open scheduler
```

In the dashboard:
1. Click "Add Job"
2. Command: `rails news:fetch_latest`
3. Frequency: Every hour (or every 6 hours to save API calls)
4. Click "Save"

### Option B: Custom Cron (Advanced)

Create `lib/tasks/scheduler.rake`:
```ruby
desc "Fetch latest news (for Heroku Scheduler)"
task fetch_news: :environment do
  puts "Fetching latest news..."
  FetchNewsJob.perform_now(mode: :latest)
  puts "Done!"
end
```

---

## Step 13: Monitor Performance

```bash
# View app metrics
heroku metrics

# View Redis metrics
heroku redis:info

# View database stats
heroku pg:info
```

---

## Troubleshooting

### Redis SSL Errors

```bash
# Check REDIS_URL format
heroku config:get REDIS_URL
# Should start with rediss:// (with SSL)

# Verify SSL fix is deployed
heroku run rails runner "puts Redis.new(url: ENV['REDIS_URL'], ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }).ping"
# Should output: PONG
```

### No News Stories

```bash
# Check if NEWS_API_KEY is set
heroku config:get NEWS_API_KEY

# Test API manually
heroku run rails news:test_api

# Fetch news manually
heroku run rails news:fetch_latest
```

### Interpretations Not Generating

```bash
# Check if worker dyno is running
heroku ps
# Should show: worker.1: up

# Check Sidekiq logs
heroku logs --tail --dyno worker

# Check if OPENAI_API_KEY is set
heroku config:get OPENAI_API_KEY

# Manually trigger interpretation
heroku run rails console
> story = NewsStory.first
> GenerateInterpretationsJob.perform_now(story.id)
```

---

## Success Criteria

✅ App loads without errors  
✅ News stories display on homepage  
✅ 3 featured stories shown  
✅ Interpretations load when clicking personas  
✅ No Redis SSL errors in logs  
✅ Sidekiq worker processing jobs  
✅ Recurring news fetch scheduled  

---

## Post-Deployment

### Monitor API Usage

```bash
# Check NewsAPI usage
# Free tier: 100 requests/day
# With 3 categories every 6 hours = 12 requests/day ✅

# Check OpenAI usage
# Visit: https://platform.openai.com/usage
```

### Regular Maintenance

```bash
# Weekly: Check for old stories
heroku run rails news:stats

# Monthly: Archive old stories
heroku run rails news:cleanup_old
```

---

**Deployment Complete!** 🎉

Your Worldviews app is now live with:
- ✅ Smart news sync
- ✅ Auto-featured stories
- ✅ Redis SSL fix
- ✅ Background job processing
- ✅ Real-time interpretation generation

