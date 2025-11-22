# Worldviews - API Specifications

## External API Integrations

### News API (NewsAPI.org)

**Base URL:** `https://newsapi.org/v2`

**Authentication:** API Key in header or query parameter

#### Endpoint: Top Headlines

```http
GET /top-headlines
```

**Parameters:**
- `apiKey` (required): Your API key
- `country`: 2-letter ISO country code (e.g., `us`, `gb`)
- `category`: `business`, `entertainment`, `general`, `health`, `science`, `sports`, `technology`
- `pageSize`: Number of results (max 100)
- `page`: Page number

**Example Request:**
```bash
curl "https://newsapi.org/v2/top-headlines?country=us&category=technology&pageSize=10&apiKey=YOUR_API_KEY"
```

**Example Response:**
```json
{
  "status": "ok",
  "totalResults": 38,
  "articles": [
    {
      "source": {
        "id": "techcrunch",
        "name": "TechCrunch"
      },
      "author": "John Doe",
      "title": "Global tech giant announces record profits",
      "description": "The company reported unprecedented growth...",
      "url": "https://techcrunch.com/article",
      "urlToImage": "https://image.url/photo.jpg",
      "publishedAt": "2024-01-15T10:30:00Z",
      "content": "Full article content here..."
    }
  ]
}
```

**Rate Limits:**
- Free tier: 100 requests/day
- Developer tier: 500 requests/day
- Business tier: Unlimited

**Implementation:**
```ruby
# app/services/news_fetcher_service.rb
class NewsFetcherService
  BASE_URL = 'https://newsapi.org/v2'
  
  def fetch_top_headlines(category: 'general', limit: 10)
    response = HTTParty.get(
      "#{BASE_URL}/top-headlines",
      query: {
        apiKey: ENV['NEWS_API_KEY'],
        country: 'us',
        category: category,
        pageSize: limit
      }
    )
    
    parse_response(response)
  end
  
  private
  
  def parse_response(response)
    return [] unless response.success?
    
    response['articles'].map do |article|
      {
        external_id: generate_id(article),
        headline: article['title'],
        summary: article['description'],
        full_content: article['content'],
        source: article['source']['name'],
        source_url: article['url'],
        image_url: article['urlToImage'],
        published_at: article['publishedAt'],
        category: determine_category(article)
      }
    end
  end
end
```

---

### OpenAI API (GPT-4)

**Base URL:** `https://api.openai.com/v1`

**Authentication:** Bearer token in header

#### Endpoint: Chat Completions

```http
POST /chat/completions
```

**Headers:**
```
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
```

**Request Body:**
```json
{
  "model": "gpt-4-turbo-preview",
  "messages": [
    {
      "role": "system",
      "content": "You are an uncompromising far-left activist..."
    },
    {
      "role": "user",
      "content": "React to this news: Global tech giant announces record profits."
    }
  ],
  "max_tokens": 500,
  "temperature": 0.8,
  "top_p": 1,
  "frequency_penalty": 0.3,
  "presence_penalty": 0.3
}
```

**Response:**
```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "gpt-4-turbo-preview",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Obviously. Another day, another corporate behemoth extracting maximum surplus value..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 56,
    "completion_tokens": 42,
    "total_tokens": 98
  }
}
```

**Rate Limits:**
- Tier 1: 500 requests/day
- Tier 2: 3,500 requests/day
- Tier 3+: Higher limits

**Pricing (as of 2024):**
- GPT-4 Turbo: $0.01/1K input tokens, $0.03/1K output tokens
- GPT-3.5 Turbo: $0.0005/1K input tokens, $0.0015/1K output tokens

**Implementation:**
```ruby
# app/services/llm_client_service.rb
class LlmClientService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end
  
  def generate_interpretation(news_summary:, persona_prompt:, max_tokens: 500)
    cache_key = "llm/#{Digest::MD5.hexdigest("#{news_summary}#{persona_prompt}")}"
    
    Rails.cache.fetch(cache_key, expires_in: 30.days) do
      response = @client.chat(
        parameters: {
          model: 'gpt-4-turbo-preview',
          messages: [
            { role: 'system', content: persona_prompt },
            { role: 'user', content: "React to this news: #{news_summary}" }
          ],
          max_tokens: max_tokens,
          temperature: 0.8,
          frequency_penalty: 0.3,
          presence_penalty: 0.3
        }
      )
      
      {
        content: response.dig('choices', 0, 'message', 'content'),
        model: response['model'],
        tokens_used: response.dig('usage', 'total_tokens')
      }
    end
  rescue => e
    Rails.logger.error("LLM API Error: #{e.message}")
    fallback_to_anthropic(news_summary, persona_prompt, max_tokens)
  end
  
  private
  
  def fallback_to_anthropic(news_summary, persona_prompt, max_tokens)
    # Anthropic Claude fallback implementation
  end
end
```

---

### Anthropic API (Claude) - Backup

**Base URL:** `https://api.anthropic.com/v1`

**Authentication:** `x-api-key` header

#### Endpoint: Messages

```http
POST /messages
```

**Headers:**
```
x-api-key: YOUR_API_KEY
anthropic-version: 2023-06-01
Content-Type: application/json
```

**Request Body:**
```json
{
  "model": "claude-3-sonnet-20240229",
  "max_tokens": 500,
  "messages": [
    {
      "role": "user",
      "content": "You are an uncompromising far-left activist. React to this news: Global tech giant announces record profits."
    }
  ],
  "system": "You are an uncompromising far-left activist...",
  "temperature": 0.8
}
```

**Response:**
```json
{
  "id": "msg_123",
  "type": "message",
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "Obviously. Another day, another corporate behemoth..."
    }
  ],
  "model": "claude-3-sonnet-20240229",
  "usage": {
    "input_tokens": 56,
    "output_tokens": 42
  }
}
```

---

## Internal API (Future)

### REST API Endpoints

#### Get News Stories

```http
GET /api/v1/news_stories
```

**Parameters:**
- `page`: Page number (default: 1)
- `per_page`: Results per page (default: 10, max: 50)
- `category`: Filter by category
- `featured`: Boolean, show only featured stories

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "headline": "Global tech giant announces record profits",
      "summary": "The company reported...",
      "source": "TechCrunch",
      "published_at": "2024-01-15T10:30:00Z",
      "category": "technology",
      "image_url": "https://...",
      "interpretations_count": 6
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 48
  }
}
```

---

#### Get Story Interpretations

```http
GET /api/v1/news_stories/:id/interpretations
```

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "persona": {
        "id": 1,
        "name": "The Revolutionary",
        "slug": "revolutionary",
        "color": "#DC2626"
      },
      "content": "Obviously. Another day, another corporate behemoth...",
      "reactions": {
        "funny": 42,
        "insightful": 18,
        "wtf": 9
      }
    }
  ]
}
```

---

#### Create Reaction

```http
POST /api/v1/interpretations/:id/reactions
```

**Request Body:**
```json
{
  "reaction_type": "funny"
}
```

**Response:**
```json
{
  "success": true,
  "total_reactions": 43
}
```

---

## Webhook Events (Future)

### New Story Published

```json
{
  "event": "story.published",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "story_id": 123,
    "headline": "...",
    "category": "technology"
  }
}
```

### Interpretation Generated

```json
{
  "event": "interpretation.generated",
  "timestamp": "2024-01-15T10:35:00Z",
  "data": {
    "interpretation_id": 456,
    "story_id": 123,
    "persona_id": 1
  }
}
```

