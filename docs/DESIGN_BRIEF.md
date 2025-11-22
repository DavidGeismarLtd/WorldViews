# Worldviews - Design Brief

## Brand Identity

### Core Message
**"One world, many filters."**

Worldviews reveals how the same factual news generates wildly different interpretations through ideological lenses. We're not here to tell you which view is "correct"—we're here to show you they all exist, and they're all a bit ridiculous.

### Brand Personality

**Playful** - We don't take ourselves too seriously  
**Irreverent** - We poke fun at everyone, including ourselves  
**Self-Aware** - We know this is satire, and we want you to know too  
**Educational** - Hidden beneath the humor is real media literacy  
**Inclusive** - Everyone's bias is fair game, no sacred cows  

### Tone of Voice

**Do:**
- Use humor and wit
- Be conversational and accessible
- Acknowledge the absurdity
- Invite critical thinking
- Celebrate diverse perspectives

**Don't:**
- Be preachy or moralistic
- Take political sides
- Claim objectivity
- Use academic jargon
- Shame users for their views

---

## Visual Identity

### Logo Concepts

**Option 1: Filtered Globe**
- A globe with multiple colored lens filters overlaid
- Each filter represents a different persona
- Suggests "seeing the world through different lenses"

**Option 2: Perspective Wheel**
- Circular wheel divided into persona segments
- Rotatable/dynamic feeling
- Like a color wheel but for worldviews

**Option 3: Split Prism**
- Single news beam splitting into multiple colored interpretations
- Clean, geometric
- Suggests "one truth, many refractions"

### Color Palette

**Primary Colors** (Persona-Specific):
- Revolutionary Red: `#DC2626`
- Moderate Gray: `#6B7280`
- Patriot Blue: `#1E40AF`
- Skeptic Purple: `#7C3AED`
- Disruptor Cyan: `#06B6D4`
- Burnt-Out Teal: `#14B8A6`

**Neutral Colors** (UI):
- Background: `#FFFFFF` (white)
- Surface: `#F9FAFB` (light gray)
- Text Primary: `#111827` (near black)
- Text Secondary: `#6B7280` (medium gray)
- Border: `#E5E7EB` (light gray)

**Accent Colors**:
- Success: `#10B981` (green)
- Warning: `#F59E0B` (amber)
- Error: `#EF4444` (red)
- Info: `#3B82F6` (blue)

### Typography

**Headlines:**
- Font: Inter Bold or Archivo Black
- Weight: 700-900
- Style: Strong, attention-grabbing
- Use: Story headlines, persona names

**Body Text:**
- Font: Inter Regular or System UI
- Weight: 400-500
- Style: Clean, readable
- Use: News summaries, interpretations

**Persona Text:**
- Varies by persona for flavor
- Revolutionary: All-caps, bold
- Moderate: Clean sans-serif
- Patriot: Serif (Georgia, Times)
- Skeptic: Monospace or typewriter
- Disruptor: Geometric sans-serif
- Burnt-Out: Casual, rounded

### Iconography

**Persona Avatars:**
- Simple, bold icons
- Flat design with single color
- Recognizable at small sizes
- Examples:
  - Revolutionary: Raised fist ✊
  - Moderate: Balance scales ⚖️
  - Patriot: Eagle or shield 🦅
  - Skeptic: Eye in pyramid 👁️
  - Disruptor: Rocket 🚀
  - Burnt-Out: Coffee cup ☕

**UI Icons:**
- Heroicons or Lucide icon set
- Consistent stroke width
- 24px base size
- Outline style for most, solid for emphasis

---

## User Interface Design

### Layout Principles

**1. Mobile-First**
- Design for vertical scrolling
- Thumb-friendly tap targets
- Swipe gestures for navigation
- Bottom navigation bar

**2. Content-Focused**
- News and interpretations are the hero
- Minimal chrome and UI elements
- Generous whitespace
- Clear visual hierarchy

**3. Persona-Driven**
- Each persona has distinct visual treatment
- Color-coded cards
- Unique typography per persona
- Smooth transitions between personas

### Key Screens

#### Homepage
```
┌─────────────────────────────┐
│  [Logo]    [Menu] [Account] │
├─────────────────────────────┤
│                             │
│   "One world, many filters" │
│                             │
│  ┌───────────────────────┐  │
│  │                       │  │
│  │   Featured Story      │  │
│  │   [Image]             │  │
│  │   Headline            │  │
│  │   3 persona previews  │  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  Today's Stories            │
│  ┌─────┐ ┌─────┐ ┌─────┐   │
│  │Story│ │Story│ │Story│   │
│  │  1  │ │  2  │ │  3  │   │
│  └─────┘ └─────┘ └─────┘   │
│                             │
└─────────────────────────────┘
```

#### Story Detail (Mobile)
```
┌─────────────────────────────┐
│  [← Back]         [Share]   │
├─────────────────────────────┤
│                             │
│  News Headline              │
│  Source • Date              │
│                             │
│  [News Image]               │
│                             │
│  Factual Summary            │
│  Lorem ipsum dolor sit...   │
│                             │
├─────────────────────────────┤
│                             │
│  ┌───────────────────────┐  │
│  │ 👤 The Revolutionary  │  │
│  │ ─────────────────────│  │
│  │                       │  │
│  │ "Obviously. Another   │  │
│  │ day, another corporate│  │
│  │ behemoth extracting..." │
│  │                       │  │
│  │ [😂 42] [🤔 18] [😱 9]│  │
│  └───────────────────────┘  │
│                             │
│  ← Swipe for next persona → │
│  ● ○ ○ ○ ○ ○               │
│                             │
│  [Compare All Views]        │
│                             │
└─────────────────────────────┘
```

#### Comparison View
```
┌─────────────────────────────┐
│  [← Back]         [Share]   │
├─────────────────────────────┤
│  Story Headline             │
├─────────────────────────────┤
│  ┌───────────┬───────────┐  │
│  │Revolutionary│ Moderate │  │
│  │           │           │  │
│  │ "Obviously│ "Well,    │  │
│  │ Another..." │both..."  │  │
│  └───────────┴───────────┘  │
│  ┌───────────┬───────────┐  │
│  │  Patriot  │  Skeptic  │  │
│  │           │           │  │
│  │ "Good.    │ "Oh great │  │
│  │ Success..." │More..."  │  │
│  └───────────┴───────────┘  │
│                             │
│  [Download Image]           │
└─────────────────────────────┘
```

---

## Component Design

### Persona Card

**Structure:**
```html
<div class="persona-card" data-persona="revolutionary">
  <div class="persona-header">
    <img src="avatar.svg" class="persona-avatar">
    <h3 class="persona-name">The Revolutionary</h3>
    <span class="persona-tagline">Everything is class struggle</span>
  </div>
  <div class="persona-content">
    <p class="interpretation-text">
      Obviously. Another day, another corporate behemoth...
    </p>
  </div>
  <div class="persona-actions">
    <button class="reaction-btn">😂 <span>42</span></button>
    <button class="reaction-btn">🤔 <span>18</span></button>
    <button class="reaction-btn">😱 <span>9</span></button>
    <button class="share-btn">Share</button>
  </div>
</div>
```

**Styling:**
- Border-left: 4px solid persona color
- Background: White with subtle persona color tint
- Shadow: Soft drop shadow on hover
- Transition: Smooth fade-in animation

### News Summary Card

**Structure:**
```html
<div class="news-card">
  <img src="news-image.jpg" class="news-image">
  <div class="news-content">
    <span class="news-meta">BBC News • 2 hours ago</span>
    <h2 class="news-headline">Global tech giant announces...</h2>
    <p class="news-summary">The company reported...</p>
    <div class="news-actions">
      <a href="#" class="btn-primary">See All Perspectives</a>
    </div>
  </div>
</div>
```

### Share Image Template

**Layout:**
```
┌─────────────────────────────────┐
│  WORLDVIEWS                     │
│  One world, many filters        │
├─────────────────────────────────┤
│                                 │
│  "Global tech giant announces   │
│   record profits"               │
│                                 │
├─────────────────────────────────┤
│  👤 The Revolutionary           │
│                                 │
│  "Obviously. Another day,       │
│   another corporate behemoth    │
│   extracting maximum surplus    │
│   value while workers barely    │
│   afford rent."                 │
│                                 │
├─────────────────────────────────┤
│  worldviews.app                 │
└─────────────────────────────────┘
```

**Specs:**
- Size: 1200x630px (Open Graph standard)
- Format: PNG with transparency
- Branding: Logo + URL at bottom
- Persona color accent

---

## Animation & Interaction

### Micro-Interactions

**Persona Switching:**
- Swipe gesture triggers slide animation
- Outgoing persona fades out left/right
- Incoming persona fades in from opposite side
- Duration: 300ms ease-in-out

**Reaction Buttons:**
- Hover: Scale up 1.1x
- Click: Bounce animation
- Counter increments with number flip

**Share Button:**
- Click: Ripple effect
- Success: Checkmark animation
- Copy link: Toast notification

### Loading States

**Skeleton Screens:**
- Show placeholder cards while loading
- Pulse animation on gray blocks
- Maintain layout to prevent shift

**Progressive Loading:**
- Load first 2-3 personas immediately
- Lazy load remaining personas
- "Load more" button if needed

---

## Responsive Design

### Breakpoints

- **Mobile:** < 640px (single column)
- **Tablet:** 640px - 1024px (2 columns)
- **Desktop:** > 1024px (3-4 columns)

### Mobile Optimizations

- Full-width cards
- Swipe navigation
- Bottom sheet for filters
- Sticky header with minimal chrome

### Desktop Enhancements

- Side-by-side comparison by default
- Hover states for all interactive elements
- Keyboard shortcuts (arrow keys)
- Multi-column story grid

---

## Accessibility

### WCAG 2.1 AA Compliance

**Color Contrast:**
- Text: Minimum 4.5:1 ratio
- Large text: Minimum 3:1 ratio
- Interactive elements: Clear focus states

**Keyboard Navigation:**
- Tab order follows visual flow
- Arrow keys for persona switching
- Enter/Space for actions
- Escape to close modals

**Screen Readers:**
- Semantic HTML (article, nav, main)
- ARIA labels for icons
- Alt text for all images
- Live regions for dynamic content

**Motion:**
- Respect `prefers-reduced-motion`
- Disable animations if requested
- Provide static alternatives

