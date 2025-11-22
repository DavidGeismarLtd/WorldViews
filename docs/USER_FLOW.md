# Worldviews - User Flow Documentation

## Primary User Journeys

### Journey 1: First-Time Visitor

```
Landing Page
    ↓
See Today's Featured Story
    ↓
View Default Persona Interpretation
    ↓
Swipe/Click to Next Persona
    ↓
"Aha!" Moment - See the Contrast
    ↓
Explore More Personas
    ↓
Share Favorite Interpretation
    ↓
[Optional] Sign Up for Daily Digest
```

**Detailed Steps:**

1. **Landing Page**
   - Hero section with tagline: "One world, many filters"
   - Featured news story of the day
   - Animated preview showing persona switching
   - Clear CTA: "See How Different Worldviews React"

2. **First Interpretation**
   - News headline and factual summary displayed prominently
   - First persona (e.g., "Hardcore Leftist Firebrand") shown with:
     - Avatar/icon
     - Persona name
     - Interpretation in speech bubble or card
   - Visual cue: "Swipe to see other perspectives"

3. **Persona Switching**
   - Swipe gesture (mobile) or arrow buttons (desktop)
   - Smooth animation between personas
   - Persona indicator dots at bottom
   - Each persona has distinct visual styling

4. **Engagement**
   - "Share this take" button on each interpretation
   - "Compare all views" button to see side-by-side
   - Reaction buttons (😂, 🤔, 😱) for each interpretation

5. **Conversion**
   - After viewing 3+ personas, prompt to sign up
   - Benefits: daily stories, save favorites, unlock all personas
   - Social login options (Google, Twitter)

---

### Journey 2: Returning User

```
Homepage
    ↓
Browse Today's Stories (3-5 items)
    ↓
Select Story of Interest
    ↓
Quick-Swipe Through Personas
    ↓
Share Comparison Image
    ↓
Check "Trending Interpretations"
    ↓
[Optional] Play "Guess the Persona" Game
```

**Detailed Steps:**

1. **Homepage Dashboard**
   - Grid of 3-5 top news stories
   - Each card shows:
     - News headline
     - Preview of 2-3 persona reactions
     - "View all perspectives" CTA
   - Filter by category (Politics, Tech, World, Business)

2. **Story Detail Page**
   - Full news summary at top
   - Carousel of persona interpretations
   - Keyboard shortcuts for power users (←/→ arrows)
   - "Compare" mode toggle

3. **Comparison View**
   - Split-screen or grid layout
   - 2-4 personas side-by-side
   - Highlight contrasting phrases
   - "Download as image" for sharing

4. **Social Features**
   - "Trending" tab shows most-shared interpretations
   - User comments on interpretations
   - Vote on "most accurate caricature"

5. **Gamification**
   - "Guess the Persona" challenge
   - Show interpretation, hide persona name
   - Multiple choice or free text guess
   - Leaderboard for accuracy

---

### Journey 3: Educational User (Teacher/Student)

```
Educational Landing Page
    ↓
Browse Curated Story Collections
    ↓
Select "Media Literacy Lesson Pack"
    ↓
View Story + All Personas
    ↓
Access Discussion Questions
    ↓
Download Classroom Materials
    ↓
Assign to Students
```

**Detailed Steps:**

1. **Educational Portal**
   - Separate section for educators
   - Pre-curated story collections by topic
   - Lesson plans and discussion guides
   - Standards alignment (Common Core, etc.)

2. **Classroom Mode**
   - Projector-friendly layout
   - Step-by-step reveal of personas
   - Discussion prompts between each persona
   - Printable worksheets

3. **Student Assignments**
   - "Create your own persona" activity
   - "Identify the bias" exercises
   - Reflection journals
   - Peer discussion forums

---

## Key User Flows by Feature

### Flow A: News Story Browsing

```
Homepage → Story Grid → Filter/Sort → Story Detail → Persona Carousel
```

**Interactions:**
- Infinite scroll or pagination
- Filter by date, category, popularity
- Search by keyword
- Bookmark stories for later

### Flow B: Persona Exploration

```
Story Detail → Persona 1 → Swipe → Persona 2 → Swipe → ... → Compare All
```

**Interactions:**
- Swipe left/right (mobile)
- Click arrows (desktop)
- Tap persona dots for direct access
- "Shuffle" button for random persona

### Flow C: Social Sharing

```
View Interpretation → Click Share → Choose Format → Select Platform → Post
```

**Share Formats:**
- Single persona card (image)
- Side-by-side comparison (2-4 personas)
- Animated GIF of persona switching
- Link with preview card

**Platforms:**
- Twitter/X (optimized for character limit)
- Facebook (with context)
- Instagram Stories (vertical format)
- LinkedIn (professional framing)
- Copy link

### Flow D: User Account

```
Sign Up → Onboarding → Preferences → Daily Digest → Profile
```

**Account Features:**
- Save favorite stories
- Customize persona order
- Set digest frequency (daily, weekly)
- Track reading history
- Manage notifications

---

## Mobile-Specific Flows

### Mobile Optimization

1. **Swipe-First Interface**
   - Tinder-like swipe mechanics
   - Haptic feedback on persona change
   - Full-screen persona cards
   - Bottom sheet for news details

2. **Progressive Web App (PWA)**
   - Add to home screen
   - Offline reading of cached stories
   - Push notifications for new stories
   - Fast loading with service workers

3. **Mobile Sharing**
   - Native share sheet integration
   - Instagram Story templates
   - WhatsApp-optimized formatting
   - Screenshot with attribution

---

## Error States & Edge Cases

### No News Available
- Show yesterday's stories
- Display "Checking for updates" message
- Suggest browsing archive

### LLM API Failure
- Show cached interpretations
- Display "Persona is taking a break" message
- Offer to notify when available

### Slow Loading
- Skeleton screens for personas
- Progressive loading (show 2-3 first)
- "Load more personas" button

### No Internet Connection
- Offline mode with cached content
- Clear messaging about limited functionality
- Queue actions for when online

---

## Conversion Funnels

### Free → Paid Conversion

```
Free User (3 stories/day)
    ↓
Hit Story Limit
    ↓
Paywall with Benefits
    ↓
7-Day Free Trial
    ↓
Payment
    ↓
Premium User (unlimited)
```

### Casual → Engaged Conversion

```
One-Time Visitor
    ↓
Email Capture (daily digest)
    ↓
Regular Email Engagement
    ↓
Account Creation
    ↓
Daily Active User
```

