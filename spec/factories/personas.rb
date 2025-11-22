FactoryBot.define do
  factory :persona do
    sequence(:name) { |n| "Test Persona #{n}" }
    sequence(:slug) { |n| "test-persona-#{n}" }
    description { Faker::Lorem.sentence }
    system_prompt { Faker::Lorem.paragraph(sentence_count: 3) }
    avatar_url { Faker::Avatar.image }
    color_primary { "##{Faker::Color.hex_color}" }
    color_secondary { "##{Faker::Color.hex_color}" }
    display_order { rand(1..100) }
    active { true }
    official { false }
    visibility { "public" }
    user { nil }

    trait :inactive do
      active { false }
    end

    trait :official do
      official { true }
      user { nil }
    end

    trait :custom do
      official { false }
      user
    end

    trait :private_persona do
      visibility { "private" }
    end

    trait :unlisted do
      visibility { "unlisted" }
    end

    trait :revolutionary do
      name { "The Revolutionary" }
      slug { "the-revolutionary" }
      description { "Fighting the power, one headline at a time" }
      color_primary { "#DC2626" }
      color_secondary { "#991B1B" }
      display_order { 1 }
    end

    trait :moderate do
      name { "The Moderate" }
      slug { "the-moderate" }
      description { "Both sides are overreacting, as usual" }
      color_primary { "#6B7280" }
      color_secondary { "#374151" }
      display_order { 2 }
    end

    trait :patriot do
      name { "The Patriot" }
      slug { "the-patriot" }
      description { "God, guns, and glory" }
      color_primary { "#1E40AF" }
      color_secondary { "#1E3A8A" }
      display_order { 3 }
    end
  end
end
