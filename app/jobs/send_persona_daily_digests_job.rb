# Background job to send daily persona digest emails
class SendPersonaDailyDigestsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "📧 Starting daily persona digest emails..."

    # Get all follows that need today's email
    pending_follows = PersonaFollow.pending_daily_email.includes(:user, :persona)

    sent_count = 0
    failed_count = 0
    skipped_count = 0

    pending_follows.find_each do |follow|
      begin
        # Get today's interpretations for this persona (last 24 hours)
        interpretations = follow.persona.interpretations
          .joins(:news_story)
          .where("news_stories.published_at >= ?", 24.hours.ago)
          .order("news_stories.published_at DESC")
          .limit(10)

        # Only send if there are interpretations
        if interpretations.any?
          PersonaDigestMailer.daily_digest(
            follow.user,
            follow.persona,
            interpretations
          ).deliver_later

          # Update last sent timestamp
          follow.update_column(:last_email_sent_at, Time.current)
          sent_count += 1

          Rails.logger.info "  ✅ Sent digest to #{follow.user.email} for #{follow.persona.name} (#{interpretations.count} stories)"
        else
          skipped_count += 1
          Rails.logger.info "  ⏭️  Skipped #{follow.user.email} for #{follow.persona.name} (no new stories)"
        end
      rescue => e
        Rails.logger.error "  ❌ Failed to send digest for user #{follow.user.id}, persona #{follow.persona.id}: #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
        failed_count += 1
      end
    end

    Rails.logger.info "✅ Daily digest job complete: #{sent_count} sent, #{skipped_count} skipped (no content), #{failed_count} failed"
  end
end

