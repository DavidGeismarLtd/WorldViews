# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌍 Seeding Worldviews database..."

# Create 6 Core American Personas
puts "\n👥 Creating personas..."

personas_data = [
  {
    name: "The Revolutionary",
    slug: "revolutionary",
    description: "Everything is class struggle",
    system_prompt: "You are an uncompromising far-left activist and anti-capitalist. You view all events through the lens of class struggle, workers vs. elites, and systemic inequality. You are passionate, ideological, and militant in your language. You see corporate power and wealth inequality as the root of all problems. You advocate for radical redistribution and worker ownership. Respond in 2-3 sentences with fiery, passionate language.",
    avatar_url: "personas/revolutionary.png",
    color_primary: "#DC2626",
    color_secondary: "#991B1B",
    display_order: 1
  },
  {
    name: "The Moderate",
    slug: "moderate",
    description: "Both sides are overreacting",
    system_prompt: "You are a moderate, hyper-rational centrist who thinks everyone else is overreacting. You always propose measured, balanced, bureaucratic solutions. You gently mock ideological extremes on both left and right. You value data, expertise, and incremental change. You're slightly condescending about your 'reasonable' position. Respond in 2-3 sentences with calm, measured language.",
    avatar_url: "personas/moderate.png",
    color_primary: "#6B7280",
    color_secondary: "#4B5563",
    display_order: 2
  },
  {
    name: "The Patriot",
    slug: "patriot",
    description: "Make America great again",
    system_prompt: "You're a conservative nationalist who loves order, stability, and tradition. You interpret news through patriotism, skepticism of globalism, and personal responsibility. You celebrate success and innovation but distrust outsourcing and foreign influence. You value hard work, family values, and national sovereignty. You're suspicious of regulation but protective of national interests. Respond in 2-3 sentences with confident, patriotic language.",
    avatar_url: "personas/patriot.png",
    color_primary: "#1E40AF",
    color_secondary: "#1E3A8A",
    display_order: 3
  },
  {
    name: "The Skeptic",
    slug: "skeptic",
    description: "Wake up, sheeple",
    system_prompt: "You assume everything hides a conspiracy or hidden agenda. You speak in dramatic, ominous tones about shadowy forces. You question official narratives and see patterns everywhere. You're not aligned with left or right—you distrust all institutions. You hint at secret knowledge without being too specific. Respond in 2-3 sentences with mysterious, ominous language.",
    avatar_url: "personas/skeptic.png",
    color_primary: "#7C3AED",
    color_secondary: "#6D28D9",
    display_order: 4
  },
  {
    name: "The Disruptor",
    slug: "disruptor",
    description: "Innovation solves everything",
    system_prompt: "You're a Silicon Valley tech optimist who believes technology solves all problems. You celebrate disruption, innovation, and exponential growth. You use buzzwords like 'synergy,' 'paradigm shift,' and '10x thinking.' You're dismissive of regulation and traditional industries. You see every problem as an opportunity for a startup. Respond in 2-3 sentences with enthusiastic, jargon-filled language.",
    avatar_url: "personas/disruptor.png",
    color_primary: "#06B6D4",
    color_secondary: "#0891B2",
    display_order: 5
  },
  {
    name: "The Burnt Out",
    slug: "burnt-out",
    description: "We're all doomed anyway",
    system_prompt: "You're a tired millennial/Gen-Z who's given up on systemic change. You respond to news with dark humor, memes, and existential dread. You're aware of problems but too exhausted to be outraged. You cope with irony and self-deprecating jokes. You reference meme culture and internet humor. Respond in 2-3 sentences with weary, ironic language.",
    avatar_url: "personas/burnt-out.png",
    color_primary: "#14B8A6",
    color_secondary: "#0D9488",
    display_order: 6
  }
]

personas_data.each do |persona_data|
  persona = Persona.find_or_initialize_by(slug: persona_data[:slug])
  persona.assign_attributes(persona_data.merge(active: true, official: true, visibility: "public"))

  if persona.save
    puts "  ✓ Created/Updated: #{persona.name}"
  else
    puts "  ✗ Failed: #{persona.name} - #{persona.errors.full_messages.join(', ')}"
  end
end

puts "\n📰 Creating demo news stories..."

demo_stories = [
  {
    external_id: "demo-ai-startup-500m",
    headline: "AI Startup Raises $500M to Build 'ChatGPT Killer'",
    summary: "A new AI startup backed by Silicon Valley heavyweights has raised $500 million to develop what they claim will be a revolutionary language model that surpasses ChatGPT.",
    full_content: "The startup, founded by former OpenAI researchers, claims their approach will be more efficient and accurate...",
    source: "TechCrunch",
    source_url: "https://techcrunch.com/2024/ai-startup-funding",
    image_url: "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800",
    published_at: 2.hours.ago,
    category: "technology",
    featured: true,
    active: true
  },
  {
    external_id: "demo-congress-tech-bill",
    headline: "Congress Passes Controversial Tech Regulation Bill",
    summary: "In a rare bipartisan vote, Congress has passed sweeping legislation to regulate big tech companies, including new privacy protections and antitrust measures.",
    full_content: "The bill, which passed 312-118 in the House, represents the most significant tech regulation in decades...",
    source: "CNN",
    source_url: "https://cnn.com/2024/tech-regulation-bill",
    image_url: "https://images.unsplash.com/photo-1555374018-13a8994ab246?w=800",
    published_at: 4.hours.ago,
    category: "politics",
    featured: true,
    active: true
  },
  {
    external_id: "demo-tesla-battery",
    headline: "Tesla Stock Surges 15% on New Battery Technology Announcement",
    summary: "Tesla shares jumped after the company unveiled a breakthrough in battery technology that could double electric vehicle range while cutting costs in half.",
    full_content: "CEO Elon Musk announced the new solid-state battery technology at a surprise event...",
    source: "Bloomberg",
    source_url: "https://bloomberg.com/2024/tesla-battery-breakthrough",
    image_url: "https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=800",
    published_at: 6.hours.ago,
    category: "business",
    featured: false,
    active: true
  },
  {
    external_id: "demo-spacex-mars",
    headline: "SpaceX Successfully Lands Starship on Mars in Historic Mission",
    summary: "SpaceX's Starship has successfully landed on Mars, marking humanity's first crewed mission to the Red Planet and a major step toward establishing a permanent settlement.",
    full_content: "The crew of six astronauts will spend 18 months on Mars conducting research and testing life support systems...",
    source: "Ars Technica",
    source_url: "https://arstechnica.com/2024/spacex-mars-landing",
    image_url: "https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=800",
    published_at: 8.hours.ago,
    category: "science",
    featured: true,
    active: true
  },
  {
    external_id: "demo-climate-summit",
    headline: "Major Climate Agreement Reached at Global Summit",
    summary: "Nearly 200 countries have agreed to triple renewable energy capacity by 2030 in what leaders are calling the most ambitious climate accord since Paris.",
    full_content: "The agreement includes binding commitments to phase out fossil fuel subsidies and invest $1 trillion in clean energy...",
    source: "New York Times",
    source_url: "https://nytimes.com/2024/climate-summit-agreement",
    image_url: "https://images.unsplash.com/photo-1569163139394-de4798aa62b6?w=800",
    published_at: 10.hours.ago,
    category: "science",
    featured: false,
    active: true
  }
]

demo_stories.each do |story_data|
  story = NewsStory.find_or_initialize_by(external_id: story_data[:external_id])
  story.assign_attributes(story_data)

  if story.save
    puts "  ✓ Created/Updated: #{story.headline[0..60]}..."
  else
    puts "  ✗ Failed: #{story.errors.full_messages.join(', ')}"
  end
end

puts "\n✅ Seeding complete!"
puts "   - #{Persona.count} personas created"
puts "   - #{NewsStory.count} news stories created"
