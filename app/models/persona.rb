# == Schema Information
#
# Table name: personas
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE), not null
#  avatar_url      :string
#  color_primary   :string
#  color_secondary :string
#  description     :text
#  display_order   :integer          default(0)
#  name            :string           not null
#  official        :boolean          default(FALSE), not null
#  slug            :string           not null
#  system_prompt   :text             not null
#  visibility      :string           default("public"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :bigint
#
# Indexes
#
#  index_personas_on_active         (active)
#  index_personas_on_display_order  (display_order)
#  index_personas_on_slug           (slug) UNIQUE
#  index_personas_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Persona < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  has_many :interpretations, dependent: :destroy
  has_many :news_stories, through: :interpretations

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :system_prompt, presence: true
  validates :visibility, inclusion: { in: %w[public private unlisted] }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  after_commit :enqueue_avatar_generation, on: :create, if: -> { avatar_url.blank? && !official? }
  after_commit :broadcast_avatar_update, if: :saved_change_to_avatar_url?

  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(display_order: :asc, created_at: :asc) }
  scope :official, -> { where(official: true) }
  scope :custom, -> { where(official: false) }
  scope :public_personas, -> { where(visibility: 'public') }
  scope :by_user, ->(user) { where(user: user) }

  # Instance methods
  def to_param
    slug
  end

  def generate_interpretation_for(news_story)
    InterpretationGeneratorService.new(
      news_story: news_story,
      persona: self
    ).generate!
  end

  def recent_interpretations(limit = 10)
    interpretations
      .includes(:news_story)
      .order(created_at: :desc)
      .limit(limit)
  end

  def total_interpretations
    interpretations.count
  end

  def average_interpretation_length
    return 0 if interpretations.empty?

    interpretations.average("LENGTH(content)").to_i
  end

  def most_common_category
    interpretations
      .joins(:news_story)
      .group("news_stories.category")
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(1)
      .pluck("news_stories.category")
      .first
  end

  # Authorization methods
  def viewable_by?(current_user)
    return true if official?
    return true if visibility == "public"
    return false if visibility == "private" && current_user.nil?
    return true if user_id == current_user&.id

    visibility == "unlisted"
  end

  def editable_by?(current_user)
    return false if current_user.nil?
    return false if official?

    user_id == current_user.id
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end

  def enqueue_avatar_generation
    GeneratePersonaAvatarJob.perform_async(id)
  end

  def broadcast_avatar_update
    # Only broadcast if avatar_url was just added (not nil -> has URL)
    return unless avatar_url.present?

    Rails.logger.info "📡 Broadcasting avatar update for persona ##{id} (#{name})"

    # Broadcast the update via Turbo Stream to replace avatar images
    broadcast_replace_to(
      "persona_#{id}",
      target: "persona_avatar_#{id}",
      partial: "personas/avatar",
      locals: { persona: self }
    )
  end
end
