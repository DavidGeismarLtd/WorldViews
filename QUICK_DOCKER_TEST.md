# 🚀 Quick Docker Test Guide

The **fastest way** to test if your Docker image works before deploying.

## Option 1: Automated Test Script (Recommended)

Run the automated test script:

```bash
./test-docker.sh
```

This will:
- ✅ Check if Docker is running
- ✅ Verify config/master.key exists
- ✅ Build the Docker image
- ✅ Start PostgreSQL, Redis, and Rails
- ✅ Run health checks
- ✅ Show you the status

**Then visit:** http://localhost:3000

---

## Option 2: Manual Docker Compose

```bash
# Build and start everything
docker-compose up --build

# Visit http://localhost:3000
```

**Stop with:**
```bash
docker-compose down
```

---

## Option 3: Quick Build Test Only

Just want to test if the image builds?

```bash
docker build -t worldviews .
```

If this completes without errors, your Dockerfile is valid! ✅

---

## What to Test

Once running at http://localhost:3000:

1. ✅ **Homepage loads** - Should see hero section and personas
2. ✅ **Click a news story** - Should load story detail page
3. ✅ **Click a persona** - Should load persona profile
4. ✅ **Generate interpretation** - Click "See [Persona]'s Take"
5. ✅ **Check styling** - CSS and images should load
6. ✅ **Check console** - No JavaScript errors

---

## Troubleshooting

### "RAILS_MASTER_KEY is missing"
```bash
# Make sure this file exists:
cat config/master.key

# If it doesn't exist, you need to get it from:
# - Your local development environment
# - Your team's secure storage
# - Regenerate with: rails credentials:edit
```

### "Container exits immediately"
```bash
# Check the logs:
docker-compose logs web

# Common issues:
# - Missing RAILS_MASTER_KEY
# - Database connection failed
# - Missing environment variables
```

### "Can't connect to database"
```bash
# Wait for PostgreSQL to be ready:
docker-compose up -d db
sleep 10
docker-compose up web
```

### "Assets not loading (blank page)"
```bash
# Rebuild with no cache:
docker-compose down
docker-compose build --no-cache
docker-compose up
```

---

## Cleanup

```bash
# Stop services
docker-compose down

# Stop and remove all data (fresh start)
docker-compose down -v

# Remove the built image
docker rmi worldviews
```

---

## Success = Ready to Deploy! 🎉

If you can:
- ✅ Build the image without errors
- ✅ Start the container successfully
- ✅ Load the homepage at http://localhost:3000
- ✅ See styled content (not blank page)
- ✅ Navigate between pages

**You're ready to deploy to production!**

Next: See `DOCKER_TESTING.md` for detailed testing or proceed with deployment to Fly.io/Render.

