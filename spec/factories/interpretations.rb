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
FactoryBot.define do
  factory :interpretation do
    association :news_story
    association :persona
    content { Faker::Lorem.paragraph(sentence_count: 5) }
    llm_model { "gpt-4-turbo-preview" }
    llm_tokens_used { rand(100..500) }
    generation_time_ms { rand(1000..5000) }
    cached { false }
    metadata { { provider: "openai", generated_at: Time.current } }

    trait :cached do
      cached { true }
    end

    trait :from_claude do
      llm_model { "claude-3-sonnet-20240229" }
      metadata { { provider: "anthropic", generated_at: Time.current } }
    end
  end
end

