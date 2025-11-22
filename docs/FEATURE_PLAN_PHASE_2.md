# 🚀 Worldviews - Phase 2 Feature Plan

**Date:** November 20, 2025
**Status:** Planning
**Features:** Persona Avatars, Persona Show Pages, User Authentication & Custom Personas

---

## 📋 Table of Contents

1. [Feature 1: Persona Avatars](#feature-1-persona-avatars)
2. [Feature 2: Persona Show Pages](#feature-2-persona-show-pages)
3. [Feature 3: User Authentication & Custom Personas](#feature-3-user-authentication--custom-personas)
4. [Implementation Order](#implementation-order)
5. [Database Changes](#database-changes)
6. [Technical Decisions](#technical-decisions)

---

## Feature 1: Persona Avatars

### 🎯 Goal
Create funny, cartoonesque avatars for each of the 6 core personas that visually represent their worldview and personality.

### 🎨 Design Approach

**Style Guidelines:**
- **Cartoonesque/Satirical** - Exaggerated features that match personality
- **Consistent style** - All 6 should feel like they're from the same "universe"
- **Color-coded** - Match existing persona colors (red, gray, blue, purple, cyan, teal)
- **Expressive** - Facial expressions that capture their vibe
- **Simple & Bold** - Work well at small sizes (64x64 to 256x256)

**Avatar Concepts:**

1. **🔴 The Revolutionary** (Red #DC2626)
   - Raised fist, Che Guevara-style beret
   - Angry/determined expression
   - Red bandana or socialist imagery
   - Maybe holding a megaphone or protest sign

2. **⚪ The Moderate** (Gray #6B7280)
   - Glasses, business casual attire
   - Calm, slightly smug expression
   - Holding scales or "both sides" gesture
   - NPR tote bag or coffee mug

3. **🔵 The Patriot** (Blue #1E40AF)
   - American flag imagery (hat, shirt, background)
   - Strong jaw, confident expression
   - Eagle or stars & stripes motif
   - Maybe holding a Bible or Constitution

4. **🟣 The Skeptic** (Purple #7C3AED)
   - Tinfoil hat or third eye symbol
   - Suspicious, wide-eyed expression
   - Magnifying glass or conspiracy board
   - "Wake up sheeple" energy

5. **🔷 The Disruptor** (Cyan #06B6D4)
   - Hoodie, tech startup aesthetic
   - Excited/manic expression
   - Laptop or rocket ship imagery
   - "Move fast and break things" vibe

6. **🟢 The Burnt Out** (Teal #14B8A6)
   - Messy hair, tired eyes, coffee cup
   - Exhausted/dead inside expression
   - Phone in hand, dark circles under eyes
   - Millennial/Gen-Z aesthetic

### 🛠️ Implementation Options

**Option A: AI-Generated (Recommended for MVP)**
- Use DALL-E 3 or Midjourney to generate avatars
- Pros: Fast, consistent style, high quality
- Cons: Requires API costs or manual generation
- **Estimated time:** 2-4 hours (including iterations)

**Option B: Commission Artist**
- Hire illustrator on Fiverr/Upwork
- Pros: Fully custom, professional quality
- Cons: More expensive ($50-200), slower (3-7 days)

**Option C: Use Existing Avatar Libraries**
- DiceBear, Avataaars, or similar
- Pros: Free, instant
- Cons: Less unique, harder to match personality

### 📁 File Structure

```
app/assets/images/personas/
  ├── revolutionary.png (or .svg)
  ├── moderate.png
  ├── patriot.png
  ├── skeptic.png
  ├── disruptor.png
  └── burnt_out.png
```

### 🔧 Technical Implementation

1. **Generate/Create Avatars** (manual step)
2. **Add to assets pipeline** - Place in `app/assets/images/personas/`
3. **Update seeds.rb** - Set `avatar_url` for each persona
4. **Update views** - Display avatars in persona carousel and cards
5. **Add CSS** - Style avatars (circular, bordered, hover effects)

### ✅ Acceptance Criteria

- [ ] All 6 personas have unique, cartoonesque avatars
- [ ] Avatars match persona colors and personalities
- [ ] Avatars display correctly in persona carousel
- [ ] Avatars display correctly in story detail page
- [ ] Avatars are optimized for web (< 50KB each)

---

## Feature 2: Persona Show Pages

### 🎯 Goal
Create dedicated pages for each persona (`/personas/:slug`) that explain their worldview, show their system prompt, and display their recent interpretations.

### 📄 Page Structure

**URL Pattern:** `/personas/:slug` (e.g., `/personas/the-revolutionary`)

**Page Sections:**

1. **Hero Section**
   - Large avatar
   - Persona name
   - Tagline/description
   - Color-themed background

2. **"Where Do My Ideas Come From?" Section**
   - Heading: "Where Do My Ideas Come From?"
   - Display the system prompt in a styled box
   - Make it feel like the persona is "revealing their secrets"
   - Maybe use a speech bubble or thought bubble design

3. **Recent Interpretations Section**
   - "Recent Takes" or "Latest Hot Takes"
   - Show 5-10 recent interpretations from this persona
   - Each interpretation shows:
     - News headline (linked to story)
     - Interpretation snippet
     - Date
     - "Read full story" link

4. **Stats Section (Optional)**
   - Total interpretations generated
   - Most common topics
   - Average interpretation length

### 🎨 Design Mockup

```
┌─────────────────────────────────────────────────┐
│  [AVATAR]                                       │
│  The Revolutionary                              │
│  "Fighting the power, one headline at a time"   │
│  [Red themed background]                        │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  💭 Where Do My Ideas Come From?                │
│                                                 │
│  [System Prompt in styled box]                  │
│  "You are a far-left revolutionary activist..." │
│                                                 │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  🔥 Recent Hot Takes                            │
│                                                 │
│  📰 "Congress Passes Tech Bill"                 │
│  "This is just another example of how..."       │
│  [Read full story →]                            │
│                                                 │
│  📰 "Tesla Stock Surges"                        │
│  "Follow the money—it always leads back..."     │
│  [Read full story →]                            │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 🔧 Technical Implementation

**1. Routes**
```ruby
# config/routes.rb
resources :personas, only: [:index, :show], param: :slug
```

**2. Controller**
```ruby
# app/controllers/personas_controller.rb
class PersonasController < ApplicationController
  def index
    @personas = Persona.active.ordered
  end

  def show
    @persona = Persona.find_by!(slug: params[:slug])
    @recent_interpretations = @persona.interpretations
                                      .includes(:news_story)
                                      .order(created_at: :desc)
                                      .limit(10)
  end
end
```

**3. Views**
- `app/views/personas/index.html.erb` - All personas grid
- `app/views/personas/show.html.erb` - Individual persona page

**4. Model Updates**
```ruby
# app/models/persona.rb
# Add method to get recent interpretations
def recent_interpretations(limit = 10)
  interpretations.includes(:news_story).order(created_at: :desc).limit(limit)
end

# Add stats methods
def total_interpretations
  interpretations.count
end
```

### ✅ Acceptance Criteria

- [ ] Each persona has a dedicated show page at `/personas/:slug`
- [ ] Page displays avatar, name, description
- [ ] System prompt is displayed in "Where Do My Ideas Come From?" section
- [ ] Recent interpretations are listed with links to stories
- [ ] Page is styled with persona's color theme
- [ ] Mobile responsive design

---

## Feature 3: User Authentication & Custom Personas

### 🎯 Goal
Allow users to create accounts and build their own custom personas with unique worldviews and system prompts.

### 🏗️ Architecture Overview

This is the most complex feature. It requires:
1. User authentication system
2. User-persona ownership model
3. Custom persona creation UI
4. Permission system (who can see/use which personas)
5. Interpretation generation for custom personas

### 📊 Database Schema Changes

**New Tables:**

```ruby
# users table
create_table :users do |t|
  t.string :email, null: false, index: { unique: true }
  t.string :password_digest, null: false
  t.string :username, null: false, index: { unique: true }
  t.string :display_name
  t.string :avatar_url
  t.boolean :admin, default: false
  t.timestamps
end

# Update personas table
add_column :personas, :user_id, :bigint, index: true
add_column :personas, :visibility, :string, default: 'public'
  # visibility: 'public' (everyone), 'private' (only creator), 'unlisted' (anyone with link)
add_column :personas, :official, :boolean, default: false
  # official: true for the 6 core personas, false for user-created

# persona_favorites table (optional - for users to "favorite" personas)
create_table :persona_favorites do |t|
  t.references :user, null: false, foreign_key: true
  t.references :persona, null: false, foreign_key: true
  t.timestamps

  t.index [:user_id, :persona_id], unique: true
end
```

### 🔐 Authentication Strategy

**Option A: Devise (Recommended)**
- Industry standard Rails authentication
- Pros: Battle-tested, feature-rich, well-documented
- Cons: Heavy, opinionated
- **Estimated time:** 2-3 hours

**Option B: has_secure_password (Lightweight)**
- Built into Rails, minimal dependencies
- Pros: Simple, lightweight, full control
- Cons: Need to build everything (password reset, confirmations, etc.)
- **Estimated time:** 4-6 hours (with all features)

**Option C: Rodauth**
- Modern, flexible authentication framework
- Pros: Lightweight, modular, secure
- Cons: Less familiar, smaller community
- **Estimated time:** 3-4 hours

**Recommendation:** Use **Devise** for MVP speed, can refactor later if needed.

### 🎨 User Flows

**Flow 1: Sign Up**
```
1. User clicks "Sign Up" in navbar
2. Fill out form: email, username, password
3. Email confirmation (optional for MVP)
4. Redirect to dashboard or persona creation
```

**Flow 2: Create Custom Persona**
```
1. User clicks "Create Persona" (requires login)
2. Fill out form:
   - Name (e.g., "The Crypto Bro")
   - Description (short tagline)
   - System Prompt (the worldview)
   - Color (primary & secondary)
   - Avatar (upload or URL)
   - Visibility (public/private/unlisted)
3. Preview interpretation (optional)
4. Save persona
5. Redirect to persona show page
```

**Flow 3: View Story with Custom Personas**
```
1. User views a story
2. See official 6 personas + their own custom personas
3. Can toggle between "Official" and "My Personas" tabs
4. Interpretations generate on-demand (same as official)
```

### 🔧 Technical Implementation

**Phase 3A: Authentication (Week 1)**

1. **Install Devise**
```bash
bundle add devise
rails generate devise:install
rails generate devise User
rails db:migrate
```

2. **Add User fields**
```ruby
rails generate migration AddFieldsToUsers username:string:uniq display_name:string avatar_url:string admin:boolean
```

3. **Create authentication views**
- Sign up form
- Login form
- Password reset
- User profile/settings

4. **Add navigation**
- "Sign Up" / "Login" buttons (when logged out)
- "My Personas" / "Profile" / "Logout" (when logged in)

**Phase 3B: Custom Personas (Week 2)**

1. **Update Persona model**
```ruby
# app/models/persona.rb
belongs_to :user, optional: true
validates :user_id, presence: true, unless: :official?

scope :official, -> { where(official: true) }
scope :custom, -> { where(official: false) }
scope :public_personas, -> { where(visibility: 'public') }
scope :for_user, ->(user) { where(user: user) }

def official?
  official == true
end

def owned_by?(user)
  user_id == user&.id
end
```

2. **Create PersonasController actions**
```ruby
# app/controllers/personas_controller.rb
before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

def new
  @persona = current_user.personas.build
end

def create
  @persona = current_user.personas.build(persona_params)
  if @persona.save
    redirect_to @persona, notice: "Persona created!"
  else
    render :new
  end
end

def edit
  @persona = current_user.personas.find_by!(slug: params[:slug])
end

def update
  @persona = current_user.personas.find_by!(slug: params[:slug])
  if @persona.update(persona_params)
    redirect_to @persona, notice: "Persona updated!"
  else
    render :edit
  end
end

private

def persona_params
  params.require(:persona).permit(
    :name, :description, :system_prompt,
    :avatar_url, :color_primary, :color_secondary,
    :visibility
  )
end
```

3. **Create persona form views**
- `app/views/personas/new.html.erb`
- `app/views/personas/edit.html.erb`
- `app/views/personas/_form.html.erb` (shared form partial)

4. **Update story show page**
```ruby
# app/controllers/news_stories_controller.rb
def show
  @news_story = NewsStory.find(params[:id])

  # Official personas (always shown)
  @official_personas = Persona.official.active.ordered

  # User's custom personas (if logged in)
  @custom_personas = current_user ?
    Persona.for_user(current_user).active.ordered :
    []

  # Generate interpretations for all
  @interpretations = {}
  (@official_personas + @custom_personas).each do |persona|
    interpretation = @news_story.interpretation_for(persona)
    unless interpretation
      interpretation = generate_interpretation_sync(@news_story, persona)
    end
    @interpretations[persona.id] = interpretation if interpretation
  end
end
```

5. **Update UI to show tabs**
```html
<!-- app/views/news_stories/show.html.erb -->
<div class="persona-tabs">
  <button class="tab active" data-tab="official">Official Personas</button>
  <% if user_signed_in? && @custom_personas.any? %>
    <button class="tab" data-tab="custom">My Personas</button>
  <% end %>
</div>

<div class="persona-carousel" data-tab-content="official">
  <!-- Official personas carousel -->
</div>

<% if user_signed_in? && @custom_personas.any? %>
  <div class="persona-carousel hidden" data-tab-content="custom">
    <!-- Custom personas carousel -->
  </div>
<% end %>
```

### 🎨 UI Components Needed

1. **Persona Creation Form**
   - Name input
   - Description textarea
   - System prompt textarea (with character count)
   - Color pickers (primary & secondary)
   - Avatar upload or URL input
   - Visibility radio buttons
   - Preview button (shows sample interpretation)

2. **User Dashboard**
   - List of user's custom personas
   - "Create New Persona" button
   - Edit/Delete actions
   - Stats (total interpretations, views, etc.)

3. **Persona Card Updates**
   - Show "Official" badge on core personas
   - Show creator username on custom personas
   - Show visibility icon (public/private/unlisted)

### 🔒 Permissions & Security

**Authorization Rules:**
- ✅ Anyone can view official personas
- ✅ Anyone can view public custom personas
- ✅ Only creator can view private personas
- ✅ Anyone with link can view unlisted personas
- ✅ Only creator can edit/delete their personas
- ✅ Admins can edit/delete any persona

**Implementation:**
```ruby
# app/models/persona.rb
def viewable_by?(user)
  return true if official?
  return true if visibility == 'public'
  return true if visibility == 'unlisted'
  return true if owned_by?(user)
  return true if user&.admin?
  false
end

def editable_by?(user)
  return false unless user
  return true if user.admin?
  owned_by?(user)
end
```

### ✅ Acceptance Criteria

**Authentication:**
- [ ] Users can sign up with email/username/password
- [ ] Users can log in and log out
- [ ] Users can reset password
- [ ] User profile page exists
- [ ] Navigation shows appropriate links based on auth state

**Custom Personas:**
- [ ] Logged-in users can create custom personas
- [ ] Persona creation form validates all fields
- [ ] Users can edit their own personas
- [ ] Users can delete their own personas
- [ ] Custom personas appear in story view for creator
- [ ] Custom personas generate interpretations correctly
- [ ] Visibility settings work (public/private/unlisted)
- [ ] Non-owners cannot edit others' personas

**UI/UX:**
- [ ] Story page shows tabs for "Official" vs "My Personas"
- [ ] Persona cards show creator info and badges
- [ ] User dashboard shows all their personas
- [ ] Mobile responsive design

---

## Implementation Order

### 🎯 Recommended Sequence

**Week 1: Avatars & Persona Pages**
1. Generate/create persona avatars (Day 1-2)
2. Add avatars to assets and update seeds (Day 2)
3. Build persona show pages (Day 3-4)
4. Style and polish (Day 5)

**Week 2: Authentication Foundation**
1. Install and configure Devise (Day 1)
2. Create user registration/login flows (Day 2)
3. Build user profile pages (Day 3)
4. Add navigation and auth UI (Day 4)
5. Testing and bug fixes (Day 5)

**Week 3: Custom Personas**
1. Update database schema (Day 1)
2. Update Persona model with user association (Day 1)
3. Build persona creation form (Day 2-3)
4. Update story view to show custom personas (Day 4)
5. Add permissions and authorization (Day 5)

**Week 4: Polish & Features**
1. User dashboard (Day 1-2)
2. Persona editing/deletion (Day 2)
3. Visibility controls (Day 3)
4. Testing and bug fixes (Day 4-5)

---

## Database Changes

### Migration Plan

```ruby
# Migration 1: Add user_id and visibility to personas
class AddUserFieldsToPersonas < ActiveRecord::Migration[8.0]
  def change
    add_reference :personas, :user, foreign_key: true, null: true
    add_column :personas, :visibility, :string, default: 'public', null: false
    add_column :personas, :official, :boolean, default: false, null: false

    # Mark existing personas as official
    reversible do |dir|
      dir.up do
        Persona.update_all(official: true)
      end
    end
  end
end

# Migration 2: Create users table (Devise will generate this)
# Migration 3: Create persona_favorites (optional)
```

---

## Technical Decisions

### 🤔 Key Questions & Answers

**Q: Should custom personas be able to interpret ALL stories or just new ones?**
A: All stories. The on-demand generation system already supports this.

**Q: Should we limit how many personas a user can create?**
A: For MVP, no limit. Can add limits later if abuse occurs (e.g., 10 personas per free user, unlimited for premium).

**Q: Should custom personas be searchable/discoverable?**
A: Phase 2: No. Phase 3: Yes, add a "Browse Community Personas" page.

**Q: How do we handle avatar uploads for custom personas?**
A: MVP: URL input only (users can use Imgur, etc.). Phase 3: Add file upload with Active Storage.

**Q: Should users be able to "fork" or copy existing personas?**
A: Great idea! Add a "Clone this persona" button. Phase 3 feature.

**Q: Rate limiting for custom persona interpretations?**
A: Yes. Limit to 50 interpretations per day per user to prevent API abuse.

### 🎨 Design System

**Color Palette for UI:**
- Primary: Keep existing persona colors
- Neutral: Grays for backgrounds
- Success: Green for confirmations
- Error: Red for errors
- Info: Blue for info messages

**Typography:**
- Headings: Bold, playful (match satirical tone)
- Body: Readable, clean
- Code/Prompts: Monospace font for system prompts

---

## 📊 Success Metrics

**Feature 1: Avatars**
- Visual appeal (subjective, user feedback)
- Load time < 1s for all avatars

**Feature 2: Persona Pages**
- Avg time on persona page > 30s
- Click-through rate to stories > 20%

**Feature 3: Custom Personas**
- User sign-up rate
- Custom personas created per user (target: 2-3)
- Custom persona interpretations generated
- User retention (return visits)

---

## 🚧 Risks & Mitigations

**Risk 1: Avatar generation takes too long**
- Mitigation: Use AI generation (DALL-E 3) for speed

**Risk 2: Custom personas create offensive content**
- Mitigation: Add content moderation, reporting system (Phase 3)

**Risk 3: API costs explode with custom personas**
- Mitigation: Rate limiting, caching, consider cheaper models for custom personas

**Risk 4: User authentication adds complexity**
- Mitigation: Use Devise (battle-tested), keep MVP simple

---

## 📝 Next Steps

1. **Review this plan** - Get feedback and approval
2. **Generate avatars** - Start with Feature 1 (quickest win)
3. **Build persona pages** - Feature 2 (no dependencies)
4. **Implement auth** - Feature 3A (foundation for custom personas)
5. **Build custom personas** - Feature 3B (most complex)

**Estimated Total Time:** 3-4 weeks (full-time) or 6-8 weeks (part-time)

---

**Questions? Concerns? Let's discuss before we start building! 🚀**
