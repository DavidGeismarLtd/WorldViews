namespace :twitter do
  desc "Setup Twitter credentials for personas"
  task setup: :environment do
    puts "🐦 Twitter Setup for Personas"
    puts "=" * 60
    puts ""
    puts "This will help you configure Twitter credentials for each persona."
    puts "You'll need to create 6 separate Twitter accounts and get API credentials"
    puts "for each one from https://developer.x.com"
    puts ""

    # Top 3 personas that will tweet daily
    top_personas = %w[revolutionary tech-bro conspiracy-theorist]

    Persona.official.active.each do |persona|
      puts ""
      puts "=" * 60
      puts "Setting up: #{persona.name} (@#{persona.slug})"
      puts "=" * 60

      # Ask if they want to enable Twitter for this persona
      print "Enable Twitter for #{persona.name}? (y/N): "
      enable = STDIN.gets.chomp.downcase

      next unless enable == "y"

      # Get Twitter handle
      print "Twitter handle (without @): "
      handle = STDIN.gets.chomp

      # Get access token
      print "Access token: "
      access_token = STDIN.gets.chomp

      # Get access token secret
      print "Access token secret: "
      access_token_secret = STDIN.gets.chomp

      # Update persona
      persona.update!(
        twitter_enabled: true,
        twitter_handle: handle,
        twitter_access_token: access_token,
        twitter_access_token_secret: access_token_secret
      )

      priority = top_personas.include?(persona.slug) ? " ⭐ (TOP 3 - will tweet daily)" : ""
      puts "✅ #{persona.name} configured!#{priority}"
    end

    puts ""
    puts "=" * 60
    puts "✅ Twitter setup complete!"
    puts ""
    puts "Enabled personas:"
    Persona.twitter_enabled.each do |p|
      priority = top_personas.include?(p.slug) ? " ⭐" : ""
      puts "  • #{p.name} (@#{p.twitter_handle})#{priority}"
    end
    puts ""
    puts "⭐ = Top 3 personas that will tweet daily"
  end

  desc "Test posting a tweet for a persona"
  task :test_post, [:persona_slug] => :environment do |_t, args|
    persona_slug = args[:persona_slug] || "revolutionary"
    persona = Persona.official.active.twitter_enabled.find_by(slug: persona_slug)

    unless persona
      puts "❌ Persona '#{persona_slug}' not found or not enabled for Twitter"
      puts ""
      puts "Available personas:"
      Persona.twitter_enabled.each do |p|
        puts "  • #{p.slug}"
      end
      exit 1
    end

    puts "🐦 Testing tweet for #{persona.name}..."
    puts ""

    # Get the latest story
    story = NewsStory.active.featured.order(published_at: :desc).first

    unless story
      puts "❌ No stories found"
      exit 1
    end

    puts "📰 Story: #{story.headline}"
    puts ""

    # Get or generate interpretation
    interpretation = story.interpretations.find_by(persona: persona)

    unless interpretation
      puts "🤖 Generating interpretation..."
      interpretation = persona.generate_interpretation_for(story)
    end

    unless interpretation
      puts "❌ Failed to generate interpretation"
      exit 1
    end

    puts "💭 Interpretation: #{interpretation.content[0..100]}..."
    puts ""

    # Post tweet
    service = XPosterService.new(persona: persona)
    result = service.post_persona_take(
      news_story: story,
      interpretation: interpretation
    )

    if result[:success]
      puts "✅ Tweet posted successfully!"
      puts "🔗 Tweet ID: #{result[:tweet_id]}"
      puts "🔗 View at: https://twitter.com/#{persona.twitter_handle}/status/#{result[:tweet_id]}"
    else
      puts "❌ Failed to post tweet"
      puts "Error: #{result[:error]}"
    end
  end

  desc "Show Twitter statistics"
  task stats: :environment do
    puts "📊 Twitter Statistics"
    puts "=" * 60
    puts ""
    puts "API Usage:"
    puts "  This month: #{TweetLog.monthly_count}/100 tweets"
    puts "  Remaining: #{TweetLog.remaining_this_month} tweets"
    puts ""
    puts "Enabled personas: #{Persona.twitter_enabled.count}"
    Persona.twitter_enabled.each do |p|
      puts "  • #{p.name} (@#{p.twitter_handle})"
      puts "    - Total tweets: #{p.tweets_count}"
      puts "    - This month: #{p.tweets_this_month}"
      puts "    - Last tweet: #{p.last_tweet_at&.strftime('%Y-%m-%d %H:%M') || 'Never'}"
    end
    puts ""
    puts "Recent tweets:"
    TweetLog.successful.recent.limit(10).each do |log|
      puts "  • #{log.posted_at.strftime('%Y-%m-%d %H:%M')} - #{log.persona.name}"
      puts "    #{log.tweet_text[0..80]}..."
    end
  end

  desc "Run the daily tweet job manually"
  task post_daily: :environment do
    puts "🐦 Running daily tweet job..."
    PostDailyPersonaTweetJob.new.perform
  end
end

