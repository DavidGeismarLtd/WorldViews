#!/bin/bash
# Docker Testing Script for Worldviews
# This script automates the testing of your Docker image

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🐳 Worldviews Docker Testing Script"
echo "===================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker is running${NC}"

# Check if RAILS_MASTER_KEY exists
if [ ! -f "config/master.key" ]; then
    echo -e "${RED}❌ config/master.key not found!${NC}"
    echo "Please create config/master.key with your Rails master key."
    exit 1
fi
echo -e "${GREEN}✅ config/master.key found${NC}"

# Export environment variables
echo "Setting up environment variables..."
export RAILS_MASTER_KEY=$(cat config/master.key)
echo -e "${GREEN}✅ RAILS_MASTER_KEY loaded from config/master.key${NC}"

# Check if NEWS_API_KEY is set
if [ -z "$NEWS_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  NEWS_API_KEY not set in environment${NC}"
    echo "Reading from .env file..."
    if [ -f ".env" ]; then
        export NEWS_API_KEY=$(grep NEWS_API_KEY .env | cut -d '=' -f2)
    fi
fi

if [ -z "$NEWS_API_KEY" ]; then
    echo -e "${RED}❌ NEWS_API_KEY is required${NC}"
    echo "Set it with: export NEWS_API_KEY=your_key_here"
    echo "Or add it to your .env file"
    exit 1
fi
echo -e "${GREEN}✅ NEWS_API_KEY is set${NC}"

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  OPENAI_API_KEY not set in environment${NC}"
    echo "Reading from .env file..."
    if [ -f ".env" ]; then
        export OPENAI_API_KEY=$(grep OPENAI_API_KEY .env | cut -d '=' -f2)
    fi
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${RED}❌ OPENAI_API_KEY is required${NC}"
    echo "Set it with: export OPENAI_API_KEY=your_key_here"
    exit 1
fi
echo -e "${GREEN}✅ OPENAI_API_KEY is set${NC}"

# Optional: Set ANTHROPIC_API_KEY if available
if [ -z "$ANTHROPIC_API_KEY" ] && [ -f ".env" ]; then
    export ANTHROPIC_API_KEY=$(grep ANTHROPIC_API_KEY .env | cut -d '=' -f2 || echo "")
fi

echo ""
echo "🏗️  Building Docker image..."
echo "This may take 2-5 minutes on first build..."
echo ""

# Build the image
if docker-compose build; then
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
else
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

# Check image size
IMAGE_SIZE=$(docker images worldviews --format "{{.Size}}" | head -n 1)
echo -e "${GREEN}📦 Image size: $IMAGE_SIZE${NC}"

echo ""
echo "🚀 Starting services..."
echo ""

# Start services in detached mode
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Services are running${NC}"
else
    echo -e "${RED}❌ Services failed to start${NC}"
    echo "Showing logs:"
    docker-compose logs
    exit 1
fi

echo ""
echo "🔍 Running health checks..."
echo ""

# Check database
if docker-compose exec -T db pg_isready -U worldviews > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
else
    echo -e "${RED}❌ PostgreSQL is not ready${NC}"
fi

# Check Redis
if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Redis is ready${NC}"
else
    echo -e "${RED}❌ Redis is not ready${NC}"
fi

# Wait a bit more for Rails to start
echo "⏳ Waiting for Rails to start..."
sleep 15

# Check if web server is responding
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|302"; then
    echo -e "${GREEN}✅ Web server is responding${NC}"
else
    echo -e "${YELLOW}⚠️  Web server might not be ready yet${NC}"
    echo "Check logs with: docker-compose logs web"
fi

echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "📝 Recent logs from web service:"
docker-compose logs --tail=20 web

echo ""
echo "=================================="
echo -e "${GREEN}🎉 Docker testing complete!${NC}"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Visit http://localhost:3000 in your browser"
echo "2. Test the application functionality"
echo "3. Check logs with: docker-compose logs -f"
echo "4. Stop services with: docker-compose down"
echo ""
echo "If everything works, you're ready to deploy! 🚀"
