# Service to post tweets to X (Twitter) API
# Handles OAuth 1.0a authentication and tweet posting for personas
#
# == Usage Examples
#
# === Test posting a simple tweet (for testing credentials):
#   persona = Persona.first
#   service = XPosterService.new(persona: persona)
#   service.send(:post_tweet, "Testing my X API credentials! 🚀")
#
# === Post a persona's take on a news story:
#   persona = Persona.find_by(slug: "tech-bro")
#   story = NewsStory.first
#   interpretation = story.interpretations.find_by(persona: persona)
#   service = XPosterService.new(persona: persona)
#   result = service.post_persona_take(news_story: story, interpretation: interpretation)
#   # => { success: true, tweet_id: "1234567890" }
#
# === Post for all personas about a story:
#   story = NewsStory.first
#   story.interpretations.each do |interpretation|
#     service = XPosterService.new(persona: interpretation.persona)
#     result = service.post_persona_take(news_story: story, interpretation: interpretation)
#     puts "#{interpretation.persona.name}: #{result[:success] ? '✅' : '❌'}"
#   end
#
# === Quick test in Rails console:
#   # Get a persona
#   persona = Persona.find_by(slug: "revolutionary")
#
#   # Get a story with an interpretation
#   story = NewsStory.joins(:interpretations).first
#   interpretation = story.interpretations.find_by(persona: persona)
#
#   # Post the tweet
#   XPosterService.new(persona: persona).post_persona_take(
#     news_story: story,
#     interpretation: interpretation
#   )
#
class XPosterService
  require "net/http"
  require "json"
  require "openssl"
  require "base64"
  require "cgi"

  class XApiError < StandardError; end

  def initialize(persona:)
    @persona = persona
    # Each persona has its own Twitter app with its own API credentials
    @api_key = persona.twitter_api_key || ENV["X_#{persona.slug.upcase.gsub('-', '_')}_API_KEY"]
    @api_secret = persona.twitter_api_secret || ENV["X_#{persona.slug.upcase.gsub('-', '_')}_API_SECRET"]
    @access_token = persona.twitter_access_token || ENV["X_#{persona.slug.upcase.gsub('-', '_')}_ACCESS_TOKEN"]
    @access_token_secret = persona.twitter_access_token_secret || ENV["X_#{persona.slug.upcase.gsub('-', '_')}_ACCESS_TOKEN_SECRET"]
  end

  # Post a tweet for a persona about a news story
  # @param news_story [NewsStory] The news story to tweet about
  # @param interpretation [Interpretation] The persona's interpretation
  # @return [Hash] Response with :success, :tweet_id, :error
  def post_persona_take(news_story:, interpretation:)
    # Check if we can post (within rate limits)
    unless TweetLog.can_post_today?
      Rails.logger.warn "⚠️ Monthly tweet limit reached (100/month)"
      return { success: false, error: "Monthly tweet limit reached" }
    end

    # Check if persona can tweet today
    unless @persona.can_tweet_today?
      Rails.logger.warn "⚠️ #{@persona.name} already tweeted today"
      return { success: false, error: "Already tweeted today" }
    end

    # Build tweet content
    tweet_text = build_tweet(news_story, interpretation)

    # Post to X API
    response = post_tweet(tweet_text)

    # Log the tweet attempt
    log_tweet(news_story, tweet_text, response)

    # Update persona's last_tweet_at if successful
    @persona.update(last_tweet_at: Time.current) if response[:success]

    response
  end

  private

  def build_tweet(news_story, interpretation)
    # Use TweetGeneratorService to create a catchy, tweet-vibe version
    tweet_generator = TweetGeneratorService.new(
      persona: @persona,
      interpretation: interpretation,
      news_story: news_story
    )

    tweet_text = tweet_generator.generate_tweet
    url = story_url(news_story)

    "#{tweet_text}\n\n#{url}"
  end

  def story_url(news_story)
    # Link back to your site
    Rails.application.routes.url_helpers.news_story_url(
      news_story,
      host: ENV["APP_HOST"] || "localhost:3000"
    )
  end

  def post_tweet(text)
    uri = URI("https://api.twitter.com/2/tweets")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    auth_header = oauth_header("POST", uri.to_s, {})
    request["Authorization"] = auth_header
    request.body = { text: text }.to_json

    Rails.logger.info "🐦 Posting tweet for #{@persona.name}..."
    Rails.logger.debug "Authorization: #{auth_header[0..50]}..."
    Rails.logger.debug "Body: #{request.body}"

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    # Note: In production, you should use VERIFY_PEER with proper certificates
    # For now, using VERIFY_NONE to bypass SSL certificate issues
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    response = http.request(request)

    if response.code == "201"
      tweet_data = JSON.parse(response.body)
      Rails.logger.info "✅ Tweet posted successfully: #{tweet_data['data']['id']}"
      { success: true, tweet_id: tweet_data["data"]["id"] }
    else
      error_body = JSON.parse(response.body) rescue response.body
      Rails.logger.error "❌ X API Error: #{response.code} - #{error_body}"
      { success: false, error: error_body }
    end
  rescue => e
    Rails.logger.error "❌ Failed to post tweet: #{e.message}"
    { success: false, error: e.message }
  end

  def log_tweet(news_story, tweet_text, response)
    TweetLog.create!(
      persona: @persona,
      news_story: news_story,
      tweet_id: response[:tweet_id],
      tweet_text: tweet_text,
      posted_at: Time.current,
      success: response[:success],
      error_message: response[:error]&.to_s
    )
  end

  # OAuth 1.0a signature generation for X API
  def oauth_header(method, url, params)
    oauth_params = {
      "oauth_consumer_key" => @api_key,
      "oauth_token" => @access_token,
      "oauth_signature_method" => "HMAC-SHA1",
      "oauth_timestamp" => Time.now.to_i.to_s,
      "oauth_nonce" => SecureRandom.hex(16),
      "oauth_version" => "1.0"
    }

    # Generate signature
    signature = generate_signature(method, url, oauth_params.merge(params))
    oauth_params["oauth_signature"] = signature

    # Build OAuth header
    header_params = oauth_params.sort.map { |k, v| "#{percent_encode(k)}=\"#{percent_encode(v)}\"" }.join(", ")
    "OAuth #{header_params}"
  end

  def generate_signature(method, url, params)
    # Create signature base string
    sorted_params = params.sort.map { |k, v| "#{percent_encode(k)}=#{percent_encode(v)}" }.join("&")
    base_string = "#{method.upcase}&#{percent_encode(url)}&#{percent_encode(sorted_params)}"

    # Create signing key
    signing_key = "#{percent_encode(@api_secret)}&#{percent_encode(@access_token_secret)}"

    # Generate HMAC-SHA1 signature
    hmac = OpenSSL::HMAC.digest("sha1", signing_key, base_string)
    Base64.strict_encode64(hmac)
  end

  def percent_encode(string)
    CGI.escape(string.to_s).gsub("+", "%20").gsub("%7E", "~")
  end
end
