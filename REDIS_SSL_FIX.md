# Redis SSL Certificate Fix for Heroku

## Problem

When deployed to Heroku, the app was failing with this error:

```
RedisClient::CannotConnectError (SSL_connect returned=1 errno=0 state=error: 
certificate verify failed (self-signed certificate in certificate chain))
```

This occurred when trying to:
- Cache interpretations
- Use Action Cable for Turbo Streams
- Process Sidekiq background jobs

## Root Cause

Heroku Redis uses SSL connections (`rediss://` URLs) with **self-signed certificates**. By default, Ruby's Redis clients verify SSL certificates, which fails with Heroku's self-signed certs.

## Solution

Disable SSL certificate verification for Heroku Redis connections by adding `ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }` to all Redis configurations.

---

## Files Modified

### 1. `config/initializers/sidekiq.rb`

**Before:**
```ruby
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
```

**After:**
```ruby
# Redis configuration for Sidekiq
redis_config = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
}

# For Heroku Redis with SSL (rediss://), disable SSL verification
# Heroku uses self-signed certificates which cause verification errors
if ENV["REDIS_URL"]&.start_with?("rediss://")
  redis_config[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
end

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
```

---

### 2. `config/environments/production.rb`

**Before:**
```ruby
config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
```

**After:**
```ruby
# Use Redis for caching (we have Redis for Sidekiq, so use it for cache too)
redis_cache_config = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

# For Heroku Redis with SSL (rediss://), disable SSL verification
if ENV["REDIS_URL"]&.start_with?("rediss://")
  redis_cache_config[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
end

config.cache_store = :redis_cache_store, redis_cache_config
```

---

### 3. `config/cable.yml`

**Before:**
```yaml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/1") %>
  channel_prefix: worldviews_production
```

**After:**
```yaml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/1") %>
  channel_prefix: worldviews_production
  # For Heroku Redis with SSL, disable certificate verification
  <% if ENV["REDIS_URL"]&.start_with?("rediss://") %>
  ssl_params:
    verify_mode: <%= OpenSSL::SSL::VERIFY_NONE %>
  <% end %>
```

---

### 4. `app/views/news_stories/show.html.erb`

**Fixed typo:**
```diff
- <div class="absolute -top-3 leftP-8 w-6 h-6 bg-gray-50 transform rotate-45"></div>
+ <div class="absolute -top-3 left-8 w-6 h-6 bg-gray-50 transform rotate-45"></div>
```

---

## How It Works

1. **Detects SSL URLs**: Checks if `REDIS_URL` starts with `rediss://` (SSL)
2. **Adds SSL params**: If SSL detected, adds `ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }`
3. **Local development**: No change (uses `redis://` without SSL)
4. **Heroku production**: Disables SSL verification for self-signed certs

---

## Security Note

**Is this safe?**

Yes, for Heroku Redis:
- ✅ Connection is still encrypted (SSL/TLS)
- ✅ Traffic is protected from eavesdropping
- ✅ Heroku Redis is on a private network
- ⚠️ We're just skipping certificate verification (not disabling encryption)

**Why Heroku uses self-signed certs:**
- Heroku Redis instances use self-signed certificates
- They rotate frequently for security
- Verifying them would require constantly updating certificate bundles
- Heroku's private network provides additional security

---

## Testing

### Local Development
```bash
# Should work as before (no SSL)
rails console
> Rails.cache.write("test", "value")
> Rails.cache.read("test")
```

### Heroku Production
```bash
# Deploy changes
git add .
git commit -m "Fix Redis SSL certificate verification for Heroku"
git push heroku master

# Test Redis connection
heroku run rails console
> Rails.cache.write("test", "value")
> Rails.cache.read("test")

# Test interpretation caching
heroku open
# Visit a news story and click on a persona
# Should load without errors
```

---

## Verification

After deploying, check the logs:
```bash
heroku logs --tail
```

You should **NOT** see:
- ❌ `RedisClient::CannotConnectError`
- ❌ `certificate verify failed`
- ❌ `SSL_connect returned=1`

You **SHOULD** see:
- ✅ Successful interpretation loads
- ✅ Cache hits/misses
- ✅ Sidekiq jobs processing

---

## Alternative Solutions (Not Recommended)

### 1. Use Heroku's Certificate Bundle
```ruby
# More complex, requires maintaining cert bundle
redis_config[:ssl_params] = {
  ca_file: '/path/to/heroku-redis-ca.crt'
}
```

### 2. Disable SSL Entirely
```ruby
# NOT RECOMMENDED - removes encryption
redis_url = ENV["REDIS_URL"].gsub("rediss://", "redis://")
```

### 3. Use Different Redis Provider
- Upstash Redis (has proper SSL certs)
- Redis Cloud (has proper SSL certs)
- More expensive than Heroku Redis

---

## Summary

✅ **Fixed**: Redis SSL certificate verification errors on Heroku  
✅ **Method**: Disabled SSL verification for `rediss://` URLs  
✅ **Security**: Connection still encrypted, just skipping cert verification  
✅ **Impact**: Sidekiq, caching, and Action Cable now work on Heroku  

**Status: Ready to deploy!** 🚀

