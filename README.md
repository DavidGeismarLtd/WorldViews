# 🌍 Worldviews

> **The news, seen through everyone's delusions**

A satirical media literacy web app that shows how the same factual news event gets interpreted through wildly different ideological lenses.

![Status](https://img.shields.io/badge/status-MVP%20Complete-success)
![Rails](https://img.shields.io/badge/Rails-8.1-red)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## 🎯 What is Worldviews?

Worldviews demonstrates how the same news story can generate completely different interpretations based on ideological perspective. Each story is processed through 6 distinct "personas" representing different worldviews:

1. **🔴 The Revolutionary** - Everything is class struggle
2. **⚪ The Moderate** - Both sides are overreacting
3. **🔵 The Patriot** - Make America great again
4. **🟣 The Skeptic** - Wake up, sheeple
5. **🔷 The Disruptor** - Innovation solves everything
6. **🟢 The Burnt Out** - We're all doomed anyway

---

## ✨ Features

- 📰 **Real News** - Fetches latest headlines from NewsAPI
- 🎭 **6 Personas** - Each with unique ideological lens
- 🤖 **AI-Generated** - Interpretations powered by GPT-4/Claude
- 📱 **Mobile-First** - Swipe between personas like TikTok
- 🎨 **Playful Design** - Comic-style speech bubbles
- ⚡ **Fast** - Aggressive caching for instant responses
- 🆓 **100% Free** - No paywalls, no ads

---

## 🚀 Quick Start

### Prerequisites

- Ruby 3.3+
- PostgreSQL 14+
- Node.js 18+ (for JavaScript)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/worldviews.git
cd worldviews

# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Start the server
bin/dev
```

Visit **http://localhost:3000** 🎉

---

## 🧪 Development Mode (No API Keys Required!)

The app works **out of the box** with mock data - no API keys needed for development!

- ✅ **Mock News** - 5 pre-seeded demo stories
- ✅ **Mock LLM** - Contextual AI-generated responses
- ✅ **Full UI** - Complete persona carousel experience

Just run `bin/rails db:seed` and start exploring!

---

## 🔑 Production Setup (Optional)

To use real APIs in production, create a `.env` file:

```bash
# News API (https://newsapi.org/register)
NEWS_API_KEY=your_newsapi_key_here

# OpenAI (https://platform.openai.com/api-keys)
OPENAI_API_KEY=your_openai_key_here

# Anthropic - Fallback (https://console.anthropic.com/)
ANTHROPIC_API_KEY=your_anthropic_key_here
```

See `.env.example` for details.

---

## 📖 Documentation

- [📋 Project Overview](docs/PROJECT_OVERVIEW.md) - Vision, features, roadmap
- [🎨 Design Brief](docs/DESIGN_BRIEF.md) - Brand identity & UI design
- [🏗️ Architecture](docs/ARCHITECTURE.md) - Technical architecture
- [👥 Personas](docs/PERSONAS.md) - The 6 core personas
- [🔄 User Flow](docs/USER_FLOW.md) - User journeys
- [📊 Build Progress](docs/BUILD_PROGRESS.md) - Current status
- [🚀 Quick Start](docs/QUICK_START.md) - Setup guide

---

## 🛠️ Tech Stack

- **Backend:** Ruby on Rails 8.1
- **Database:** PostgreSQL
- **Frontend:** Hotwire (Turbo + Stimulus)
- **Styling:** Tailwind CSS
- **Caching:** Solid Cache (Rails 8)
- **Jobs:** Solid Queue (Rails 8)
- **APIs:** NewsAPI, OpenAI GPT-4, Anthropic Claude

---

## 🎮 Usage

### Browse Stories

```bash
# Homepage shows latest news stories
open http://localhost:3000
```

### View Interpretations

```bash
# Click any story to see all 6 persona interpretations
# Swipe left/right or click tabs to switch personas
# Use arrow keys for keyboard navigation
```

### Fetch Fresh News (Production)

```bash
# In Rails console
FetchNewsJob.perform_now

# Or schedule it (every 6 hours)
# See config/schedule.rb
```

---

## 🧑‍💻 Development

### Run Tests

```bash
bin/rails test
```

### Rails Console

```bash
bin/rails console

# Try these commands:
NewsStory.count
Persona.all.pluck(:name)
Interpretation.last
```

### Generate Interpretations

```bash
# In Rails console
story = NewsStory.first
persona = Persona.find_by(slug: 'revolutionary')

service = InterpretationGeneratorService.new(
  news_story: story,
  persona: persona
)

interpretation = service.generate!
puts interpretation.content
```

---

## 🎨 Design Philosophy

- **Satirical, not mean** - Exaggerated but not cruel
- **Educational** - Highlights media bias & filter bubbles
- **Playful** - Comic-style, meme-friendly aesthetic
- **Fast & fun** - TikTok-style swipe navigation
- **Accessible** - Works on all devices, no login required

---

## 🗺️ Roadmap

- [x] **Phase 1:** MVP with 6 US personas (English)
- [ ] **Phase 2:** Multi-language support
- [ ] **Phase 3:** Country-specific personas
- [ ] **Phase 4:** User-submitted personas
- [ ] **Phase 5:** Social sharing & virality features

---

## 🤝 Contributing

Contributions welcome! This is a satirical educational project.

---

## 📄 License

MIT License - See LICENSE file

---

## ⚠️ Disclaimer

All persona interpretations are AI-generated parodies for educational purposes. They represent exaggerated stereotypes, not real people or organizations. Don't take them seriously!

---

**Built with ❤️ and a healthy dose of skepticism**
