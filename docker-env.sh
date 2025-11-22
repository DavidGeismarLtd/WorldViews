#!/bin/bash
# Source this file to set Docker environment variables
# Usage: source docker-env.sh

export RAILS_MASTER_KEY=$(cat config/master.key)
export OPENAI_API_KEY=$(grep OPENAI_API_KEY .env | cut -d '=' -f2)
export NEWS_API_KEY=$(grep NEWS_API_KEY .env | cut -d '=' -f2)
export ANTHROPIC_API_KEY=$(grep ANTHROPIC_API_KEY .env | cut -d '=' -f2 || echo "")

echo "✅ Environment variables loaded!"
echo "   RAILS_MASTER_KEY: ${RAILS_MASTER_KEY:0:10}..."
echo "   OPENAI_API_KEY: ${OPENAI_API_KEY:0:10}..."
echo "   NEWS_API_KEY: ${NEWS_API_KEY:0:10}..."
echo ""
echo "You can now run: docker-compose logs -f web"
