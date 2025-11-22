class NewsStory < ApplicationRecord
  # Associations
  has_many :interpretations, dependent: :destroy
  has_many :personas, through: :interpretations

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
end
