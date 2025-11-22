class NewsStory < ApplicationRecord
  # Associations
  has_many :interpretations, dependent: :destroy
  has_many :personas, through: :interpretations

  # Callbacks
  after_commit :update_featured_stories, on: [ :create, :update ]

  # Validations
  validates :external_id, presence: true, uniqueness: true
  validates :headline, presence: true
  validates :source, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :featured, -> { where(featured: true) }
  scope :recent, -> { order(published_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }

  # Class methods
  def self.latest(limit = 10)
    active.recent.limit(limit)
  end

  def self.last_fetch_time
    maximum(:published_at) || 7.days.ago
  end

  def self.needs_sync?
    last_fetch_time < 6.hours.ago
  end

  # Instance methods
  def featured?
    featured
  end

  def generate_interpretations!
    Persona.active.ordered.each do |persona|
      GenerateInterpretationJob.perform_later(id, persona.id)
    end
  end

  def interpretation_for(persona)
    interpretations.find_by(persona: persona)
  end

  def fetch_full_content
    return full_content if full_content.present? && !full_content.include?("[+")

    # Try to scrape full content from source URL
    scraped_content = ArticleScraperService.new(source_url).scrape_content

    if scraped_content.present?
      update(full_content: scraped_content)
      scraped_content
    else
      # Fallback to summary if scraping fails
      summary || headline
    end
  end

  def content_for_interpretation
    # Use full content if available, otherwise use headline + summary
    if full_content.present? && !full_content.include?("[+")
      full_content
    else
      text = headline.dup
      text += ". #{summary}" if summary.present?
      text
    end
  end

  private

  # Automatically mark the 3 newest stories as featured
  def update_featured_stories
    # Get the 3 most recent active stories by published_at
    top_3_ids = NewsStory.active
                         .order(published_at: :desc)
                         .limit(3)
                         .pluck(:id)

    # Unfeature all stories first
    NewsStory.where(featured: true).where.not(id: top_3_ids).update_all(featured: false)

    # Feature the top 3
    NewsStory.where(id: top_3_ids).update_all(featured: true)
  end
end
