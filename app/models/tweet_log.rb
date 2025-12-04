class TweetLog < ApplicationRecord
  belongs_to :persona
  belongs_to :news_story

  # Validations
  validates :tweet_text, presence: true
  validates :posted_at, presence: true

  # Scopes
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  scope :recent, -> { order(posted_at: :desc) }
  scope :this_month, -> { where("posted_at >= ?", 1.month.ago) }

  # Class methods for tracking API usage
  def self.monthly_count
    this_month.successful.count
  end

  def self.remaining_this_month
    100 - monthly_count # Free tier limit
  end

  def self.can_post_today?
    remaining_this_month > 0
  end

  def self.usage_by_persona
    this_month.successful
      .group(:persona_id)
      .count
  end
end
