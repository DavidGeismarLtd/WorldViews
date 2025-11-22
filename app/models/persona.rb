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
end
