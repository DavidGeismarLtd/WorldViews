FactoryBot.define do
  factory :tweet_log do
    persona { nil }
    news_story { nil }
    tweet_id { "MyString" }
    tweet_text { "MyText" }
    posted_at { "2025-11-30 19:42:20" }
    success { false }
    error_message { "MyText" }
  end
end
