# 🐳 Docker Testing Guide

This guide will help you test your Docker image locally before deploying to production.

## Prerequisites

- Docker Desktop installed and running
- Your `config/master.key` file (for Rails credentials)
- API keys ready (NEWS_API_KEY, OPENAI_API_KEY)

## Quick Start

### 1. Build and Test with Docker Compose (Recommended)

This is the **easiest way** to test your full production stack locally:

```bash
# Build and start all services (PostgreSQL, Redis, Rails)
docker-compose up --build

# Visit http://localhost:3000 in your browser
```

**What this does:**
- ✅ Builds your production Docker image
- ✅ Starts PostgreSQL database
- ✅ Starts Redis for Sidekiq
- ✅ Runs database migrations automatically
- ✅ Starts Rails server on port 3000

### 2. Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove all data (fresh start)
docker-compose down -v
```

---

## Manual Docker Testing (Without Compose)

If you want to test the Docker image in isolation:

### Step 1: Build the Image

```bash
docker build -t worldviews .
```

**Expected output:**
```
[+] Building 120.5s (18/18) FINISHED
 => [internal] load build definition from Dockerfile
 => => transferring dockerfile: 2.31kB
 => [internal] load .dockerignore
 ...
 => exporting to image
 => => naming to docker.io/library/worldviews
```

### Step 2: Run PostgreSQL

```bash
docker run -d \
  --name worldviews-db \
  -e POSTGRES_USER=worldviews \
  -e POSTGRES_PASSWORD=worldviews_password \
  -e POSTGRES_DB=worldviews_production \
  -p 5432:5432 \
  postgres:16
```

### Step 3: Run Redis

```bash
docker run -d \
  --name worldviews-redis \
  -p 6379:6379 \
  redis:7-alpine
```

### Step 4: Run Your App

```bash
docker run -d \
  --name worldviews-web \
  -p 3000:80 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e DATABASE_URL=postgres://worldviews:worldviews_password@host.docker.internal:5432/worldviews_production \
  -e REDIS_URL=redis://host.docker.internal:6379/0 \
  -e NEWS_API_KEY=your_newsapi_key_here \
  -e OPENAI_API_KEY=your_openai_key_here \
  -e RAILS_LOG_TO_STDOUT=true \
  -e RAILS_SERVE_STATIC_FILES=true \
  worldviews
```

### Step 5: Check Logs

```bash
# View Rails logs
docker logs -f worldviews-web

# Check if database migrations ran
docker logs worldviews-web | grep "Migrating"
```

### Step 6: Test the App

Visit http://localhost:3000 in your browser.

### Step 7: Cleanup

```bash
docker stop worldviews-web worldviews-db worldviews-redis
docker rm worldviews-web worldviews-db worldviews-redis
```

---

## Testing Checklist

Use this checklist to verify your Docker image works correctly:

### ✅ Build Phase
- [ ] Docker image builds without errors
- [ ] Build completes in reasonable time (2-5 minutes)
- [ ] No missing dependencies errors
- [ ] Assets precompile successfully

### ✅ Runtime Phase
- [ ] Container starts without crashing
- [ ] Database connection works
- [ ] Redis connection works
- [ ] Migrations run automatically
- [ ] Server starts on port 80 (mapped to 3000)

### ✅ Application Phase
- [ ] Homepage loads (http://localhost:3000)
- [ ] Static assets load (CSS, JS, images)
- [ ] Can view news stories
- [ ] Can view personas
- [ ] Can generate interpretations
- [ ] Background jobs work (if Sidekiq enabled)

### ✅ Production Readiness
- [ ] No development dependencies included
- [ ] Image size is reasonable (<500MB)
- [ ] Logs output to STDOUT
- [ ] Environment variables work
- [ ] SSL/HTTPS ready (when deployed)

---

## Common Issues & Solutions

### Issue: "RAILS_MASTER_KEY is missing"

**Solution:**
```bash
# Make sure config/master.key exists
cat config/master.key

# Pass it to Docker
export RAILS_MASTER_KEY=$(cat config/master.key)
docker-compose up
```

### Issue: "Database connection failed"

**Solution:**
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check PostgreSQL logs
docker logs worldviews-db-1

# Wait for PostgreSQL to be ready
docker-compose up -d db
sleep 10
docker-compose up web
```

### Issue: "Assets not loading (404 errors)"

**Solution:**
```bash
# Make sure RAILS_SERVE_STATIC_FILES is set
docker-compose down
docker-compose up --build

# Check if assets were precompiled
docker run --rm worldviews ls -la public/assets
```

### Issue: "Container exits immediately"

**Solution:**
```bash
# Check container logs
docker-compose logs web

# Run container interactively to debug
docker run -it --rm \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  worldviews /bin/bash

# Inside container, try running Rails manually
./bin/rails console
```

### Issue: "Build is very slow"

**Solution:**
```bash
# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1
docker build -t worldviews .

# Or with docker-compose
DOCKER_BUILDKIT=1 docker-compose build
```

---

## Advanced Testing

### Test Database Migrations

```bash
# Start only the database
docker-compose up -d db

# Run migrations manually
docker-compose run --rm web ./bin/rails db:migrate

# Check migration status
docker-compose run --rm web ./bin/rails db:migrate:status
```

### Test Sidekiq Background Jobs

```bash
# Uncomment the sidekiq service in docker-compose.yml
# Then start all services
docker-compose up --build

# Check Sidekiq logs
docker-compose logs -f sidekiq

# Test a background job in Rails console
docker-compose run --rm web ./bin/rails console
# In console:
# FetchNewsJob.perform_later
```

### Test with Production Data

```bash
# Seed the database
docker-compose run --rm web ./bin/rails db:seed

# Or run custom seeds
docker-compose run --rm web ./bin/rails runner "
  NewsStory.create!(
    headline: 'Test Story',
    summary: 'This is a test',
    source: 'Test Source',
    published_at: Time.current
  )
"
```

### Inspect the Built Image

```bash
# Check image size
docker images worldviews

# Inspect image layers
docker history worldviews

# Run shell inside the image
docker run -it --rm worldviews /bin/bash

# Check what's installed
docker run --rm worldviews bundle list
docker run --rm worldviews ruby -v
docker run --rm worldviews rails -v
```

### Performance Testing

```bash
# Check memory usage
docker stats

# Check startup time
time docker-compose up -d web

# Check response time
curl -w "@-" -o /dev/null -s http://localhost:3000 <<'EOF'
    time_namelookup:  %{time_namelookup}\n
       time_connect:  %{time_connect}\n
    time_appconnect:  %{time_appconnect}\n
      time_redirect:  %{time_redirect}\n
   time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
         time_total:  %{time_total}\n
EOF
```

---

## Environment Variables Reference

Required for production:

```bash
RAILS_MASTER_KEY=<from config/master.key>
DATABASE_URL=postgres://user:pass@host:5432/dbname
REDIS_URL=redis://host:6379/0
NEWS_API_KEY=55c501f2c11a4b32933805c96ebf7e2e
OPENAI_API_KEY=sk-proj-...
```

Optional:

```bash
ANTHROPIC_API_KEY=sk-ant-...
RAILS_LOG_LEVEL=info
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

---

## Next Steps

Once your Docker image works locally:

1. **Push to a registry** (optional for some platforms):
   ```bash
   docker tag worldviews your-registry/worldviews:latest
   docker push your-registry/worldviews:latest
   ```

2. **Deploy to Fly.io**:
   ```bash
   flyctl launch
   flyctl deploy
   ```

3. **Deploy to Render**:
   - Connect your GitHub repo
   - Render will auto-detect the Dockerfile
   - Add environment variables in dashboard
   - Click "Deploy"

4. **Deploy with Kamal**:
   ```bash
   kamal setup
   kamal deploy
   ```

---

## Troubleshooting Commands

```bash
# View all running containers
docker ps -a

# View all images
docker images

# Remove all stopped containers
docker container prune

# Remove all unused images
docker image prune -a

# Remove all volumes (⚠️ deletes data!)
docker volume prune

# Complete cleanup (⚠️ nuclear option!)
docker system prune -a --volumes

# Rebuild from scratch
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

---

## Success Criteria

Your Docker image is ready for deployment when:

✅ **Build succeeds** without errors
✅ **Container starts** and stays running
✅ **Homepage loads** at http://localhost:3000
✅ **Database works** (can view stories, personas)
✅ **Assets load** (CSS, JS, images display correctly)
✅ **Logs are clean** (no errors in `docker-compose logs`)
✅ **Image size** is reasonable (300-500MB)
✅ **Startup time** is under 30 seconds

Once all these pass, you're ready to deploy! 🚀
