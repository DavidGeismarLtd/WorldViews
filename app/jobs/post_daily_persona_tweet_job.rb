# Background job to post daily tweets for top 3 personas
class PostDailyPersonaTweetJob < ApplicationJob
  queue_as :default

  # Top 3 most distinctive personas for daily tweeting
  TOP_PERSONAS = %w[revolutionary tech-bro conspiracy-theorist].freeze

  def perform
    Rails.logger.info "🐦 Starting daily persona tweet job..."

    # Check if we have enough API quota left
    remaining = TweetLog.remaining_this_month
    Rails.logger.info "📊 API quota: #{TweetLog.monthly_count}/100 used, #{remaining} remaining"

    if remaining < TOP_PERSONAS.length
      Rails.logger.warn "⚠️ Not enough API quota to post for all personas (need #{TOP_PERSONAS.length}, have #{remaining})"
    end

    # Get the top story of the day
    top_story = select_top_story

    unless top_story
      Rails.logger.warn "⚠️ No top story found for tweeting"
      return
    end

    Rails.logger.info "📰 Selected story: #{top_story.headline}"

    # Post tweets for each of the top 3 personas
    results = TOP_PERSONAS.map do |slug|
      post_for_persona(slug, top_story)
    end

    # Log summary
    successful = results.count { |r| r[:success] }
    failed = results.count { |r| !r[:success] }

    Rails.logger.info "✅ Daily tweet job complete: #{successful} successful, #{failed} failed"
  end

  private

  def select_top_story
    # Get the most recent featured story that hasn't been tweeted about today
    # or the most recent story if all have been tweeted about
    NewsStory.active
      .featured
      .order(published_at: :desc)
      .first
  end

  def post_for_persona(slug, news_story)
    persona = Persona.official.active.twitter_enabled.find_by(slug: slug)

    unless persona
      Rails.logger.warn "⚠️ Persona '#{slug}' not found or not enabled for Twitter"
      return { success: false, persona: slug, error: "Persona not found or not enabled" }
    end

    # Check if persona can tweet today
    unless persona.can_tweet_today?
      Rails.logger.info "⏭️ #{persona.name} already tweeted today, skipping"
      return { success: false, persona: slug, error: "Already tweeted today" }
    end

    # Get or generate interpretation
    interpretation = news_story.interpretations.find_by(persona: persona)

    unless interpretation
      Rails.logger.info "🤖 Generating interpretation for #{persona.name}..."
      interpretation = persona.generate_interpretation_for(news_story)
    end

    unless interpretation
      Rails.logger.error "❌ Failed to generate interpretation for #{persona.name}"
      return { success: false, persona: slug, error: "Failed to generate interpretation" }
    end

    # Post to X
    service = XPosterService.new(persona: persona)
    result = service.post_persona_take(
      news_story: news_story,
      interpretation: interpretation
    )

    if result[:success]
      Rails.logger.info "✅ Posted tweet for #{persona.name}: #{result[:tweet_id]}"
      { success: true, persona: slug, tweet_id: result[:tweet_id] }
    else
      Rails.logger.error "❌ Failed to post tweet for #{persona.name}: #{result[:error]}"
      { success: false, persona: slug, error: result[:error] }
    end
  rescue => e
    Rails.logger.error "❌ Error posting for #{slug}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, persona: slug, error: e.message }
  end
end

