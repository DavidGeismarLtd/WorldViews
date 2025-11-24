# == Schema Information
#
# Table name: news_stories
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(TRUE), not null
#  category     :string
#  featured     :boolean          default(FALSE), not null
#  full_content :text
#  headline     :string           not null
#  image_url    :string
#  metadata     :jsonb
#  published_at :datetime
#  source       :string           not null
#  source_url   :string
#  summary      :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string           not null
#
# Indexes
#
#  index_news_stories_on_category             (category)
#  index_news_stories_on_created_at           (created_at)
#  index_news_stories_on_external_id          (external_id) UNIQUE
#  index_news_stories_on_featured_and_active  (featured,active)
#  index_news_stories_on_published_at         (published_at)
#
FactoryBot.define do
  factory :news_story do
    sequence(:external_id) { |n| "news-#{n}-#{SecureRandom.hex(4)}" }
    headline { Faker::Lorem.sentence(word_count: 8) }
    summary { Faker::Lorem.paragraph(sentence_count: 3) }
    full_content { Faker::Lorem.paragraph(sentence_count: 10) }
    source { Faker::Company.name }
    source_url { Faker::Internet.url }
    published_at { Faker::Time.between(from: 7.days.ago, to: Time.current) }
    category { %w[general business technology sports entertainment health science].sample }
    image_url { Faker::LoremFlickr.image(size: "800x600", search_terms: ['news']) }
    featured { false }
    active { true }

    trait :featured do
      featured { true }
    end

    trait :inactive do
      active { false }
    end

    trait :with_interpretations do
      transient do
        interpretation_count { 3 }
      end

      after(:create) do |news_story, evaluator|
        create_list(:interpretation, evaluator.interpretation_count, news_story: news_story)
      end
    end
  end
end

