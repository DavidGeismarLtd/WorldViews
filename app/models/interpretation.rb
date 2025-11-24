# == Schema Information
#
# Table name: interpretations
#
#  id                 :bigint           not null, primary key
#  cached             :boolean          default(FALSE)
#  content            :text             not null
#  detailed_content   :text
#  generation_time_ms :integer
#  llm_model          :string
#  llm_tokens_used    :integer
#  metadata           :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  news_story_id      :bigint           not null
#  persona_id         :bigint           not null
#
# Indexes
#
#  index_interpretations_on_created_at                    (created_at)
#  index_interpretations_on_news_story_id                 (news_story_id)
#  index_interpretations_on_news_story_id_and_persona_id  (news_story_id,persona_id) UNIQUE
#  index_interpretations_on_persona_id                    (persona_id)
#
# Foreign Keys
#
#  fk_rails_...  (news_story_id => news_stories.id)
#  fk_rails_...  (persona_id => personas.id)
#
class Interpretation < ApplicationRecord
  # Associations
  belongs_to :news_story
  belongs_to :persona

  # Validations
  validates :content, presence: true
  validates :news_story_id, uniqueness: { scope: :persona_id }

  # Scopes
  scope :cached, -> { where(cached: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_commit :broadcast_detailed_content_update, if: :saved_change_to_detailed_content?
  after_commit :broadcast_interpretation_created, on: :create

  # Instance methods
  def cache_key_name
    "interpretation/#{news_story_id}/#{persona_id}/v2"
  end

  def mark_as_cached!
    update(cached: true)
  end

  private

  def broadcast_detailed_content_update
    # Only broadcast if detailed_content was just added (not nil -> has content)
    return unless detailed_content.present?

    Rails.logger.info "📡 Broadcasting detailed content update for interpretation ##{id}"

    # Broadcast the update via Turbo Stream
    broadcast_replace_to(
      "interpretation_#{id}",
      target: "detailed_analysis_#{id}",
      partial: "interpretations/detailed_analysis",
      locals: { interpretation: self, persona: persona }
    )
  end

  def broadcast_interpretation_created
    Rails.logger.info "📡 Broadcasting new interpretation for persona #{persona_id} on story #{news_story_id}"

    # Broadcast to the news story's stream
    broadcast_replace_to(
      "news_story_#{news_story_id}_persona_#{persona_id}",
      target: "interpretation_content_#{news_story_id}_persona_#{persona_id}",
      partial: "interpretations/content",
      locals: { interpretation: self, persona: persona }
    )
  end
end
