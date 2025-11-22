# Sidekiq + Redis Setup for Async Detailed Interpretations

## Overview

This implementation uses **Sidekiq** with **Redis** to generate detailed interpretations asynchronously. When a user clicks "Read Full Opinion", they are immediately redirected to the interpretation page with a loading state, and the detailed analysis is generated in the background and streamed to the page when ready.

## Architecture

1. **User clicks "Read Full Opinion"** → Immediate redirect to `/interpretations/:id`
2. **Controller** → Enqueues `GenerateDetailedInterpretationJob` if detailed content doesn't exist
3. **View** → Shows loading state: "The {Persona} is thinking hard about a full analysis..."
4. **Sidekiq Job** → Generates detailed interpretation in background
5. **Interpretation Model** → `after_commit` callback broadcasts Turbo Stream update
6. **Turbo Stream** → Replaces loading state with detailed content (no page reload!)

## Prerequisites

### Install Redis

**macOS (Homebrew):**
```bash
brew install redis
brew services start redis
```

**Ubuntu/Debian:**
```bash
sudo apt-get install redis-server
sudo systemctl start redis
```

**Verify Redis is running:**
```bash
redis-cli ping
# Should return: PONG
```

## Installation

### 1. Install gems
```bash
bundle install
```

### 2. Start all services
```bash
bin/dev
```

This will start:
- Rails server (port 3000)
- Tailwind CSS watcher
- Sidekiq worker

### 3. Verify Sidekiq is running

Visit: http://localhost:3000/sidekiq (you may need to add a route for this)

Or check logs:
```bash
# You should see Sidekiq startup messages in the terminal
```

## Testing

1. **Start the app:**
   ```bash
   bin/dev
   ```

2. **Visit a news story** and click on a persona interpretation

3. **Click "📝 Read Full Opinion"**

4. **You should see:**
   - Immediate redirect to interpretation page
   - Loading spinner with message: "The {Persona} is thinking hard about a full analysis..."
   - After 5-30 seconds (depending on article length), the detailed analysis appears automatically

5. **Check Sidekiq logs** to see the job processing:
   ```
   📝 [Sidekiq] Generating detailed interpretation: The Skeptic → Congress Passes...
   🤖 Generating interpretation with OpenAI GPT-4...
   ✅ Generated detailed analysis (1234 tokens)
   📡 Broadcasting detailed content update for interpretation #12
   ```

## How It Works

### 1. Controller (`app/controllers/interpretations_controller.rb`)
```ruby
def show
  @interpretation = Interpretation.find(params[:id])
  
  # Enqueue background job if detailed content doesn't exist
  if @interpretation.detailed_content.blank?
    GenerateDetailedInterpretationJob.perform_async(@interpretation.id)
  end
end
```

### 2. Sidekiq Job (`app/sidekiq/generate_detailed_interpretation_job.rb`)
- Runs in background
- Fetches full article content via web scraping
- Generates detailed interpretation using GPT-4
- Updates interpretation record (triggers `after_commit` callback)

### 3. Interpretation Model (`app/models/interpretation.rb`)
```ruby
after_commit :broadcast_detailed_content_update, if: :saved_change_to_detailed_content?

def broadcast_detailed_content_update
  broadcast_replace_to(
    "interpretation_#{id}",
    target: "detailed_analysis_#{id}",
    partial: "interpretations/detailed_analysis",
    locals: { interpretation: self, persona: persona }
  )
end
```

### 4. View (`app/views/interpretations/show.html.erb`)
```erb
<!-- Subscribe to Turbo Stream updates -->
<%= turbo_stream_from "interpretation_#{@interpretation.id}" %>

<!-- This div gets replaced when detailed content is ready -->
<div id="detailed_analysis_<%= @interpretation.id %>">
  <%= render "detailed_analysis", interpretation: @interpretation, persona: @persona %>
</div>
```

## Configuration Files

- **`config/sidekiq.yml`** - Sidekiq worker configuration
- **`config/initializers/sidekiq.rb`** - Redis connection settings
- **`config/cable.yml`** - Action Cable uses Redis for Turbo Streams
- **`Procfile.dev`** - Runs Rails + Sidekiq together with `bin/dev`

## Environment Variables

Add to your `.env` file (optional, defaults work for local development):

```bash
REDIS_URL=redis://localhost:6379/0
```

## Troubleshooting

### Redis not running
```bash
# Check if Redis is running
redis-cli ping

# Start Redis (macOS)
brew services start redis

# Start Redis (Linux)
sudo systemctl start redis
```

### Sidekiq not processing jobs
```bash
# Check Sidekiq logs in the terminal where you ran `bin/dev`
# Look for lines like:
# sidekiq | Sidekiq 7.x.x starting

# Or run Sidekiq manually:
bundle exec sidekiq -C config/sidekiq.yml
```

### Turbo Stream not updating
- Make sure Action Cable is using Redis (check `config/cable.yml`)
- Check browser console for WebSocket connection errors
- Verify `turbo_stream_from` is in the view

### Job fails with "Interpretation not found"
- The interpretation must exist before the job runs
- The controller creates it via `InterpretationGeneratorService.new(...).generate!` if needed

## Production Deployment

For production, you'll need:

1. **Redis server** (e.g., Redis Cloud, AWS ElastiCache, Heroku Redis)
2. **Sidekiq process** running separately from web server
3. **Environment variable** `REDIS_URL` set to your Redis instance

Example Heroku setup:
```bash
heroku addons:create heroku-redis:mini
heroku ps:scale worker=1
```

Add to `Procfile`:
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
```

