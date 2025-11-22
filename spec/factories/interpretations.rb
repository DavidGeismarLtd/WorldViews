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

