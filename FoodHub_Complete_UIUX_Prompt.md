# 🍽️ Food Hub — Full-Stack Ecommerce WebApp UI/UX Design Prompt

---

## 🎯 Project Overview

**Platform Name:** Food Hub  
**Type:** Multi-vendor Food Ecommerce Web Application  
**Account Types:** Admin · Seller · Rider · User (Buyer)  
**Goal:** Design a warm, appetizing, and highly functional food delivery and ordering platform that feels trustworthy, fast, and delightful to use across all four user roles.

---

## 🎨 Brand Identity & Visual Direction

### Concept
**"Fresh, Fast, and Familiar"** — Food Hub should feel like a premium local food market brought online. Warm, inviting, and community-rooted. The visual language draws from the richness of food culture — earthy tones balanced with vibrant accent colors that evoke freshness and appetite.

### Aesthetic Direction
- **Tone:** Warm Modernism — organic textures, rounded UI elements, bold food photography, clean layouts
- **Feel:** Approachable yet professional; lively but not chaotic
- **Personality:** Friendly neighborhood food hub with the polish of a premium delivery service
- **Reference Aesthetic:** Think a blend of a premium food delivery app and a curated local restaurant marketplace — clean whites, warm neutrals, punchy reds

---

## 🖌️ Color Palette

### Primary Brand Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Brand Primary | Chili Red | `#E63946` | CTAs, active states, badges, cart button, links |
| Brand Secondary | Saffron Gold | `#F4A261` | Highlights, promotions, star ratings, featured tags |
| Accent | Basil Green | `#2A9D8F` | Success states, eco/fresh tags, availability indicators |
| Page Background | Cream White | `#FFF8F1` | Global page background |
| Card Background | Warm White | `#FFFFFF` | Cards, modals, panels, dropdowns |
| Text Primary | Charcoal | `#1A1A2E` | All headlines, body text, labels |
| Text Secondary | Warm Gray | `#6B7280` | Subtext, placeholders, helper text |
| Border / Divider | Soft Blush | `#F0E6DC` | Input borders, card dividers, section lines |
| Overlay | Charcoal 70% | `rgba(26,26,46,0.7)` | Modal backdrops, image overlays |

### Role-Specific Dashboard Accent Colors

| Account Type | Accent Name | Hex | Rationale |
|---|---|---|---|
| Admin | Deep Navy | `#1D3557` | Authority, oversight, control, trustworthiness |
| Seller | Earthy Amber | `#E76F51` | Commerce, energy, warmth of merchant identity |
| Rider | Sky Blue | `#457B9D` | Speed, mobility, reliability, open road |
| User / Buyer | Chili Red | `#E63946` | Appetite stimulation, action, primary brand identity |

### Extended Shade Reference

```
Chili Red family:
  Light:   #FDECEA
  Mid:     #E63946  (primary)
  Dark:    #B02A35

Saffron Gold family:
  Light:   #FEF3E2
  Mid:     #F4A261  (primary)
  Dark:    #C07A38

Basil Green family:
  Light:   #E0F5F3
  Mid:     #2A9D8F  (primary)
  Dark:    #1A6B62
```

### Dark Mode Palette (Switchable via Toggle)

```
Background Page:    #121212
Background Card:    #1E1E1E
Background Raised:  #2A2A2A
Text Primary:       #F5F5F5
Text Secondary:     #A0A0A0
Border:             #3A3A3A
Brand accents remain identical to light mode
```

---

## 🔤 Typography

### Font Pairing

| Role | Font Family | Weight | Usage |
|------|------------|--------|-------|
| Display / Hero | **Playfair Display** | 700 Bold, 700 Italic | Hero titles, restaurant names, food item names, section headers |
| UI Headings | **DM Sans** | 600 SemiBold / 700 Bold | Dashboard titles, card headings, nav labels, modal titles |
| Body & Labels | **DM Sans** | 400 Regular / 500 Medium | Paragraphs, form labels, descriptions, button text |
| Data / IDs | **JetBrains Mono** | 400 Regular | Order IDs, tracking codes, payout amounts, table data |

### Type Scale

```
Display Hero:       64px / line-height 1.05 / Playfair Display 700
Page Title:         40px / line-height 1.1  / DM Sans 700
Section Title:      28px / line-height 1.2  / DM Sans 700
Card Title:         18px / line-height 1.3  / DM Sans 600
Body Large:         16px / line-height 1.7  / DM Sans 400
Body Regular:       14px / line-height 1.6  / DM Sans 400
Label / Helper:     13px / line-height 1.4  / DM Sans 500
Caption:            12px / line-height 1.3  / DM Sans 400
Badge / Tag:        11px / line-height 1.2  / DM Sans 600 Uppercase + 0.08em tracking
Mono Data:          13px / line-height 1.5  / JetBrains Mono 400
```

---

## 📐 Layout System

### Grid Structure

```
Desktop (>1024px):    12-column grid | 24px gutter | 80px horizontal padding | max-width 1440px
Tablet (640–1024px):   8-column grid | 20px gutter | 40px horizontal padding
Mobile (<640px):       4-column grid | 16px gutter | 16px horizontal padding
```

### Spacing Scale (8px Base Unit)

```
2px  — Hair (thin lines, icon nudges)
4px  — Micro (icon-to-text gap, tight badge padding)
8px  — XS (inline element spacing, chip padding)
12px — SM+ (internal card gap, icon margin)
16px — SM (card inner padding, input height padding, form gaps)
24px — MD (card outer margin, section inner padding)
32px — LG (between components)
40px — LG+ (sidebar item groups)
48px — XL (between page sections)
64px — 2XL (hero vertical padding)
96px — 3XL (full-page hero min-height offset)
```

### Border Radius System

```
2px   — Hairline (subtle tag underlines)
4px   — XS (data chips, micro badges)
8px   — SM (input fields, small buttons, table cells)
12px  — MD (standard cards, dropdowns, tooltips)
16px  — LG (image containers, large modals)
20px  — XL (restaurant hero cards, promo banners)
9999px — Full (pill buttons, avatar circles, status badges)
```

### Elevation / Shadow System

```
Level 0 — Flat:        No shadow (inline elements, disabled states)
Level 1 — Resting:     0 1px 3px rgba(0,0,0,0.08)   (default cards)
Level 2 — Hover:       0 4px 12px rgba(0,0,0,0.12)  (hovered cards)
Level 3 — Raised:      0 8px 24px rgba(0,0,0,0.16)  (floating panels, sticky nav)
Level 4 — Modal:       0 16px 48px rgba(0,0,0,0.22) (modals, overlays)
Level 5 — Popover:     0 24px 64px rgba(0,0,0,0.28) (context menus, tooltips)
```

---

## 🧩 Global Components

### Top Navigation Bar

```
Structure:
  [Logo + Wordmark]  [Location Selector]  [Search Bar — full stretch]  [Notifications]  [Cart]  [Avatar / Login]

Behavior:
  - Transparent on hero, white + shadow on scroll (backdrop-filter: blur(12px))
  - Search bar: pill shape, placeholder "Search food or restaurants…", category filter dropdown on left, mic icon on right
  - Cart icon shows item count badge (Chili Red, number)
  - Avatar shows initials or photo; dropdown: Profile / Orders / Logout
  - Mobile: Logo + Cart + Hamburger only; full search on dedicated Search tab
```

### Mobile Bottom Tab Bar (User-facing)

```
5 tabs: Home | Search | Orders | Cart | Profile
Active tab: Chili Red icon + label
Inactive: Gray icon, no label on smallest breakpoint
Cart tab shows badge count if cart is not empty
Height: 64px with safe area inset for iOS
```

### Sidebar Navigation (Dashboards)

```
Width: 240px expanded / 64px icon-only collapsed
Sections: Grouped with subtle dividers and group labels
Active item: Chili Red left border, light red tinted background
Hover: Light gray background
Icons: 20px, outlined style (Lucide or Phosphor)
Bottom pinned: Account info + Logout
Collapsible on tablet (icon mode), hidden on mobile (drawer instead)
```

### Buttons

```
Primary:      bg #E63946 | text #FFFFFF | border none | radius 9999px | padding 10px 24px | font DM Sans 500 14px
Secondary:    bg transparent | text #E63946 | border 1.5px #E63946 | radius 9999px | padding 10px 24px
Ghost:        bg transparent | text #E63946 | no border | padding 10px 16px
Danger:       bg #B02A35 | text #FFFFFF | for delete, cancel, remove actions
Subtle:       bg #FFF8F1 | text #1A1A2E | border 1px #F0E6DC | neutral actions
Icon Button:  40px circle | border 1px #F0E6DC | centered 20px icon
Loading:      Spinner replaces label, width locked to prevent layout shift

States:
  Hover:    10% darker background, shadow Level 2
  Active:   scale(0.97)
  Disabled: 40% opacity, cursor not-allowed
  Focus:    2px offset ring in brand red
```

### Form Elements

```
Text Input:
  Height: 48px
  Border: 1.5px solid #F0E6DC
  Radius: 8px
  Padding: 0 16px
  Focus border: #E63946 | box-shadow: 0 0 0 3px rgba(230,57,70,0.12)
  Error border: #B02A35 | helper text below in red

Select:
  Same as input + custom chevron icon right-aligned
  Options in styled dropdown, 40px per option

Textarea:
  Min-height 100px, resize vertical only

Checkbox / Radio:
  Custom styled: 18px box/circle
  Checked: Chili Red fill with white checkmark / white center dot
  Unchecked: 1.5px border #F0E6DC

Toggle Switch:
  40px × 22px pill
  On: #E63946 track, white thumb
  Off: #D1D5DB track, white thumb
  Transition: 200ms ease
```

### Cards

```
Food Item Card:
  Width: flexible (min 160px)
  Image: 16:9 ratio, border-radius top 12px, object-fit cover
  Body: 12px padding — title (14px 600), restaurant (12px gray), price (15px red 600), rating (stars + number), Add button
  Hover: shadow Level 2, image scale 1.04

Restaurant Card:
  Width: flexible (min 280px)
  Full-bleed hero image (200px height), dark gradient overlay
  Overlay text: restaurant name (Playfair 20px white), cuisine tags, delivery time, rating badge
  Footer strip: min order, delivery fee

Order Summary Card:
  Horizontal layout: status badge (left) | items summary (center) | total + CTA (right)
  Background white, border, radius 12px

Promo Banner Card:
  Full-width | gradient background (brand red to orange) | white text | image right-side
  CTA button: white text on transparent border

Rider Info Card:
  Avatar (52px circle) + name + rating + vehicle type
  Live status dot (green pulse) | phone icon button
```

### Status Badges

```
All badges: padding 4px 12px | radius 9999px | font 11px 600 uppercase

Pending:           bg #F3F4F6 | text #6B7280
Confirmed:         bg #FEF9C3 | text #854D0E
Preparing:         bg #FFEDD5 | text #9A3412
Out for Delivery:  bg #DBEAFE | text #1E40AF
Delivered:         bg #DCFCE7 | text #166534
Cancelled:         bg #FEE2E2 | text #991B1B
Refunded:          bg #F3E8FF | text #6B21A8
```

### Toast Notifications

```
Position: Top-right, 16px from edges
Width: 360px
Radius: 12px
Shadow: Level 3
Variants: Success (green left border) | Error (red) | Warning (amber) | Info (blue)
Auto-dismiss: 4000ms with progress bar
Animation: slide in from right (300ms ease), fade out (200ms)
Max stack: 3 toasts visible, queue the rest
```

### Modal / Drawer

```
Modal:
  Backdrop: rgba(26,26,46,0.65) with blur(4px)
  Container: white | radius 20px | max-width 560px | padding 32px
  Header: title (20px 600) + close X button (top right)
  Footer: action buttons right-aligned
  Entrance: fade + scale from 0.95 → 1 (220ms ease-out)

Bottom Drawer (mobile):
  Slides up from bottom | radius top-left/right 20px
  Drag handle: 36px × 4px pill, centered top
  Max height: 90vh with internal scroll
```

---

## 👤 USER (Buyer) Interface — Full Page Specs

### 1. Landing / Home Page

```
HERO SECTION
  Full-width | min-height 520px
  Background: rich food photography with dark overlay gradient (bottom-up)
  Content (centered):
    - Eyebrow tag: "Delivering across [City]"
    - H1 (Playfair Display 64px italic): "Good food, delivered fast."
    - Subtext (18px gray): "Order from hundreds of local restaurants"
    - Search bar: large pill (600px wide), left = location pin + city, center = food/restaurant input, right = red search button
    - Trust badges row: "20-min delivery" · "500+ restaurants" · "Live tracking"

CATEGORY SCROLL ROW
  Horizontal scroll (no scrollbar visible)
  Items: illustrated icon (48px) + label below
  Categories: Burgers · Pizza · Sushi · Chicken · Salads · Pasta · Desserts · Drinks · More
  Active: Chili Red border + tinted background

SECTION: "Near You"
  Title (28px 700) + "See All" ghost link (right)
  3-column grid desktop | 2-column tablet | 1-column mobile
  Restaurant cards with rating, delivery ETA, fee

PROMO BANNER
  Full-width, gradient red-to-orange | rotating (3 banners) with dot indicators
  Text: offer headline + code + CTA button

SECTION: "Top Picks This Week"
  Horizontal scroll row | Food Item Cards
  Title + subtitle "Loved by your neighbors"

SECTION: "Recently Ordered" (logged-in only)
  Horizontal scroll row | Past restaurant cards with "Reorder" quick button

SECTION: "Browse by Cuisine"
  4-column image grid | Cuisine category with overlay label

FOOTER
  4-column: About | Help | Legal | Social
  App store badges | Copyright
  Dark background #1A1A2E | white text
```

### 2. Search Results Page

```
LAYOUT: Left filter sidebar (240px) + Right results grid

FILTER SIDEBAR:
  Price range slider
  Cuisine type checkboxes (multi-select)
  Rating filter (4.0+, 4.5+)
  Delivery time (Under 30min, Under 45min)
  Dietary (Vegan, Halal, Vegetarian)
  Clear All button

RESULTS AREA:
  Sort bar: "Showing 48 results" | Sort by: Relevance / Rating / Delivery Time / Price
  Restaurant grid: 2 columns desktop, 1 column mobile
  Load more button (no infinite scroll — better performance)
  Empty state: illustration + "No results" message + suggestions
```

### 3. Restaurant / Menu Page

```
RESTAURANT HEADER (sticky on scroll)
  Banner image full-width (250px height)
  Logo circle (80px, white border) overlapping banner bottom-left
  Name (Playfair 32px) | Cuisine tags | Rating + review count | Hours badge
  Row: delivery time | delivery fee | min. order | distance

MENU LAYOUT (two-panel):
  LEFT: Category sticky sidebar (Desktop) or horizontal scrollable tabs (Mobile)
    - Category names, item count badge
    - Active: red left border
  RIGHT: Item list grouped by category
    - Category heading (20px 600)
    - Item rows: image thumbnail (80px square radius 8px) | name + description + dietary icons | price + Add button

FLOATING CART PANEL (desktop right side, 320px):
  Sticky to viewport
  Header: "Your Order" + item count
  Item list with quantity steppers (–  2  +)
  Subtotal, delivery fee, taxes
  Red checkout button (full width)
  "Add more items" link
  On mobile: collapse to bottom sticky bar with total + checkout button
```

### 4. Cart Page

```
TWO-COLUMN LAYOUT:
LEFT (item list, 65%):
  Restaurant name + "Continue shopping" link
  Item rows: image | name + customization note | stepper | price | remove icon
  "Add a note for your rider" textarea (optional)

RIGHT (order summary, 35%):
  Promo code input + Apply button
  Price breakdown:
    Subtotal: ₱XXX
    Delivery fee: ₱XX
    Discount: −₱XX  (green, if applied)
    Total: ₱XXX (bold, large)
  Checkout button (full width, primary red)
  Payment method icons row
  "Continue Shopping" link below

EMPTY CART STATE:
  Centered illustration (food bowl empty)
  "Your cart is empty"
  "Explore restaurants" button
```

### 5. Checkout Page

```
STEP INDICATOR (top):
  [1. Delivery] → [2. Payment] → [3. Review] → [4. Done]
  Active step: red circle, completed: green checkmark

STEP 1 — Delivery Address:
  Saved addresses list (radio select)
  "Add New Address" form:
    Full name | Phone | Address line 1 | Line 2 | Barangay | City | ZIP
  Map preview with draggable pin
  Delivery instructions textarea

STEP 2 — Payment:
  Options as radio cards with icons:
    Credit / Debit Card (card number form inline)
    GCash (QR code or phone number)
    Cash on Delivery
  Save card checkbox

STEP 3 — Review:
  Full order summary, address, payment method
  Estimated delivery time (ETA)
  "Place Order" button (large, red, full width)
  Terms note below

STEP 4 — Confirmation:
  Animated checkmark (green, scale-in)
  Order number (mono font, large)
  "Your order is confirmed!" message
  Estimated time display
  "Track your order" button → goes to Order Tracking
```

### 6. Order Tracking Page

```
FULL-PAGE MAP (top 60% of viewport):
  Embedded Google Maps / Mapbox
  Markers: restaurant pin | rider animated position | delivery address
  Route line: dashed from restaurant → rider → destination
  Map controls: zoom, center-on-rider button

BOTTOM PANEL (bottom 40%, scrollable):
  PROGRESS BAR: 4 steps with icons
    [Order Placed] → [Preparing] → [Picked Up] → [Delivered]
    Current step animated (pulsing dot)

  RIDER INFO CARD:
    Avatar | Full name | ★ 4.9 | Vehicle type
    Phone call button | Chat button (icon buttons)

  ETA COUNTDOWN:
    Large number (e.g., "14 min") + "estimated arrival"

  ORDER SUMMARY (collapsed, expandable accordion):
    Item list | subtotal | delivery | total

  ACTIONS:
    "Rate your order" (appears after delivery)
    "Contact Support" link
```

### 7. Profile & Account Page

```
HEADER:
  Avatar (96px circle, editable) | Name | Member since date | Loyalty tier badge

TABS: Personal Info | Orders | Addresses | Favorites | Settings

PERSONAL INFO TAB:
  Edit form: name, phone, email, birthday
  Change password section (current → new → confirm)
  Profile photo upload

ORDERS TAB:
  Filter: All / Active / Completed / Cancelled
  Order cards: restaurant + date + total + status badge + "Reorder" / "Rate" / "View" buttons

ADDRESSES TAB:
  Saved address cards with edit/delete
  "Add new address" button

FAVORITES TAB:
  Saved restaurants grid (2-col)
  Saved food items grid

SETTINGS TAB:
  Notification preferences (toggles by type: promos, orders, rider updates)
  Language selector
  Dark mode toggle
  Linked social accounts
  Delete account (danger zone, bottom)
```

---

## 🏪 SELLER Interface — Full Page Specs

### Dashboard Layout

```
SIDEBAR (left, 240px):
  [Food Hub Logo — Seller Edition, amber accent]
  Store name + avatar below logo
  Navigation groups:
    OVERVIEW:      Dashboard
    OPERATIONS:    Orders · Menu Management · Inventory
    GROWTH:        Analytics · Promotions · Reviews
    STORE:         Settings · Payouts · Support
  Bottom: Store open/closed toggle + logout

TOP BAR:
  Breadcrumb navigation (current page path)
  Notifications bell (badge count)
  "Store is OPEN" pill toggle (green) | "CLOSED" (gray)
  Avatar dropdown

CONTENT AREA:
  Page title row: h1 + primary action button (right aligned)
  Body: section-based layout with card components
```

### 1. Seller Dashboard (Overview)

```
KPI ROW (4 cards, equal width):
  Today's Orders | Today's Revenue | Avg. Rating | Pending Items
  Each card: icon (32px, amber tinted) | large number | delta vs yesterday (↑ green / ↓ red)

ORDER PIPELINE (Kanban board):
  Columns: New Orders | Preparing | Ready for Pickup | Completed
  Each column: count badge + order cards
  Order card: order ID | items summary | customer name | time | action button
  Action button changes by column: "Accept" → "Mark Ready" → (auto-completed by rider)
  Drag disabled (use action buttons only for reliability)

REVENUE CHART (7-day):
  Line chart | x-axis: days | y-axis: ₱ revenue
  Two lines: Revenue vs Orders (dual y-axis)
  Hover tooltip with exact values

RECENT REVIEWS FEED (right panel, 300px):
  Latest 5 reviews with star rating, comment excerpt, reply button
  "See all reviews" link at bottom
```

### 2. Menu Management Page

```
TOP BAR:
  Category tabs (horizontal, scrollable): All | Burgers | Sides | Drinks | Desserts | + Add Category
  "Add New Item" button (right, primary red)
  Search input (filter items by name)

ITEM GRID (3-col desktop, 2-col tablet, 1-col mobile):
  Item card:
    Thumbnail image (square, 80px) | Item name | Price | Category tag
    Availability toggle (on/off)
    Actions: Edit (pencil) | Delete (trash, danger) | Duplicate

ADD / EDIT ITEM MODAL:
  LEFT: Image upload (drag-drop area with preview, 1:1 crop)
  RIGHT FORM:
    Item name (input)
    Description (textarea, 120 char limit)
    Category (select)
    Price (currency input)
    Variants section (repeatable: name + price delta, e.g. "Size: Small / Medium / Large")
    Add-ons section (repeatable: name + price, e.g. "Extra cheese +₱20")
    Dietary flags (checkboxes: Vegan, Halal, Spicy, Contains Nuts, etc.)
    Availability toggle
    Save / Cancel buttons
```

### 3. Order Management Page

```
FILTER BAR:
  Date range picker | Status dropdown | Search by order ID / customer name

STATUS TABS:
  All | New (badge) | Preparing | Ready | Completed | Cancelled

ORDER TABLE:
  Columns: Order ID | Items (count) | Customer | Order Total | Time Placed | Status Badge | Actions
  Row actions: View Details | Accept | Reject | Mark Ready
  Row click → opens detail side panel (right drawer, 420px)

DETAIL SIDE PANEL:
  Header: Order #XXXX | Status badge | Timestamp
  Customer info: name, phone, address
  Item list: thumbnail + name + qty + line price
  Special notes / allergies (highlighted if present)
  Subtotal | Delivery fee | Total
  Rider assigned: name + ETA (if picked up)
  Actions: Print receipt | Cancel order | Contact customer
```

### 4. Analytics Page

```
HEADER ROW:
  Page title | Date range picker (Last 7 days / 30 days / Custom) | Export CSV button

ROW 1 — Summary Cards:
  Total Revenue | Total Orders | Avg. Order Value | Repeat Customer Rate

ROW 2 — Charts:
  LEFT (65%): Revenue over time — area chart with gradient fill, daily data points
  RIGHT (35%): Orders by day of week — bar chart

ROW 3:
  LEFT: Top 10 Items — ranked list with thumbnail, order count, revenue contribution %
  RIGHT: Order volume heatmap — grid of hours (x) vs days (y), colored by intensity

ROW 4:
  Customer retention: New vs Returning pie chart
  Rating trend: line chart over time
  Peak hours bar chart (hourly orders)
```

### 5. Promotions Page

```
ACTIVE PROMOS:
  Cards in 2-col grid
  Each card: Promo code (mono font, large) | Discount type badge | Valid until | Usage (X/max) | Status toggle | Edit / Delete

CREATE PROMOTION MODAL:
  Promo code input (auto-generate button)
  Discount type radio: Percentage Off | Fixed Amount Off | Buy X Get Y
  Discount value input (conditional on type)
  Minimum order value toggle + input
  Max uses (overall) + Max per customer
  Date range picker (start + end)
  Applicable items (all menu / specific items multiselect)
  Preview: "Customer saves ₱XX on orders over ₱YYY"
  Save Promotion button
```

### 6. Store Settings Page

```
TABS: Store Profile | Hours | Delivery | Payouts | Notifications

STORE PROFILE TAB:
  Store name | Tagline | Cuisine type (multiselect) | Phone | Email
  Logo upload (circle preview, 256px) | Banner upload (16:9 preview)
  Description (rich text, 500 char limit)
  Social links

HOURS TAB:
  7-row grid (Mon–Sun)
  Each row: day name | open toggle | time picker (open) | time picker (close) | holiday override note

DELIVERY TAB:
  Delivery radius (km slider with map preview)
  Minimum order amount
  Delivery fee structure: Flat / Distance-based / Free over threshold
  Estimated prep time (min slider)

PAYOUTS TAB:
  Bank name | Account name | Account number (masked)
  Payout schedule: Weekly / Bi-weekly toggle
  Payout history table: date | amount | status | receipt

NOTIFICATIONS TAB:
  Toggle by: New order (sound + push) | Cancellation | New review | Payout processed
  Email digest: daily summary toggle
```

---

## 🛵 RIDER Interface — Full Page Specs

### Layout Philosophy

```
Mobile-first, app-like experience
Large tap targets (min 44px)
Bold typography, high contrast for outdoor readability
Bottom tab navigation: Home | Orders | Earnings | Profile
Minimal chrome, maximum focus on the active task
```

### 1. Rider Home / Status Screen

```
TOP HALF:
  "Good morning, [Name]!" greeting (Playfair italic)
  TODAY'S SUMMARY ROW: Deliveries | Earnings | Online hours (3 metric pills)

MAIN TOGGLE:
  Massive pill switch (full-width, 64px height)
  ONLINE: green glow, pulsing ring
  OFFLINE: gray, "You're not receiving orders"

ACTIVE ORDER CARD (when assigned):
  Full-width prominent card, sky blue border
  Restaurant name + address (with "Navigate" button)
  Customer name + address
  Status: Picking Up / Delivering
  Primary CTA: "Mark as Picked Up" or "Mark as Delivered" (full-width button)
  Secondary: Call customer | Chat

ZONE MAP (compact, 200px height):
  Shows rider's current location on map
  Nearby available order pins (count indicator)
```

### 2. Available Orders Screen

```
HEADER:
  "Available Orders" title | filter: Nearest / Highest Pay

ORDER CARDS (stacked, swipeable):
  Card:
    Restaurant name + address (distance from rider)
    Delivery address (area name, distance)
    Estimated payout: ₱XX
    Items count
    Timer: auto-decline countdown bar (30s, red progress)
  ACTIONS:
    ACCEPT (large, green, full width)
    DECLINE (small, ghost, below)

EMPTY STATE:
  Illustration: rider resting on scooter
  "No orders right now. Hang tight!"
  Pulsing dots animation
```

### 3. Active Delivery Screen

```
FULL-SCREEN MAP (top 55%):
  Live route from current location → destination
  Route: blue dashed line
  Destination: red pin with address label
  Recenter button (bottom-right of map)

BOTTOM SHEET (45%, draggable to expand):
  ORDER HEADER:
    Order #XXXX | [Customer Name] | [Distance remaining]

  ADDRESS STRIP:
    Full delivery address | "Navigate" button (opens Google Maps / Waze)

  ORDER ITEMS (collapsed accordion):
    List of items for verification at pickup

  CUSTOMER NOTES (if any):
    Highlighted amber box with note text

  ACTION BUTTONS:
    PICKED UP: [appears at restaurant step]
    DELIVERED: [appears at customer doorstep step]

  CONTACT ROW:
    Call customer icon | Message icon | Call restaurant icon

  REPORT ISSUE link (bottom)
```

### 4. Delivery History Page

```
TOP SUMMARY CARD:
  This week: ₱X,XXX earned | X deliveries | X hrs online

FILTER BAR:
  Date range picker | Status: All / Completed / Cancelled

LIST:
  Each entry:
    Date + time (top line)
    Restaurant → Customer route (area names with arrow)
    Payout amount (right, green, bold)
    Duration | Distance (small, gray)
  Expandable: tap to see full order details

PAGINATION:
  "Load more" button at bottom
```

### 5. Earnings & Profile Page

```
HEADER:
  Profile photo (96px) | Full name | ⭐ 4.9 (X reviews)
  Vehicle type badge | Active since date

EARNINGS CARD:
  Wallet balance: ₱X,XXX.XX (large, bold)
  Withdraw button (primary, red)
  Pending payout indicator

PERFORMANCE STATS GRID (2×2):
  Completion Rate | On-Time Rate | Total Deliveries | Avg. Rating

RECENT EARNINGS TABLE:
  Date | Deliveries count | Gross | Deductions | Net payout

SETTINGS OPTIONS LIST:
  Edit profile | Change vehicle info | Notification settings | Help & Support | Privacy policy | Logout
```

---

## 🔧 ADMIN Interface — Full Page Specs

### Dashboard Layout

```
SIDEBAR (left, 260px, dark navy #1D3557):
  Food Hub Admin logo (white)
  Navigation groups:
    PLATFORM:   Overview · Live Map
    USERS:      All Users · Sellers · Riders · Buyers
    OPERATIONS: Orders · Disputes · Refunds
    FINANCE:    Revenue · Payouts · Commissions
    SYSTEM:     Settings · Reports · Audit Logs · Support
  Bottom: Admin name + super-admin badge + logout

TOP BAR (white, navy border-bottom):
  Global search (all entities: users, orders, sellers, riders)
  Date: Today's date
  Notifications center (bell with badge)
  Admin avatar + role badge dropdown
```

### 1. Admin Overview Dashboard

```
BANNER ROW:
  "Platform Overview" | Last updated: [time] | Refresh button

KPI CARDS (6 cards, 3-column×2):
  Orders Today | Revenue Today | Active Riders | Active Sellers | New Signups | Open Disputes

LIVE ACTIVITY FEED (right panel, 320px, scrollable):
  Real-time stream: "Order #1234 placed at [Seller]" | "Rider joined" | "Dispute raised"
  Time-stamped, color-coded by event type
  Pause / Resume button

CHARTS ROW:
  LEFT (50%): Revenue trend — 30-day area chart with weekly average reference line
  RIGHT (50%): Order status distribution — donut chart (today's snapshot)

BOTTOM ROW:
  Active riders map (small embedded map, rider pins clustered)
  Top 5 sellers today (table: rank, name, orders, revenue)
  Top 5 buyers today (table: rank, name, orders, spend)
```

### 2. User Management Page

```
TABS: All Users | Sellers | Riders | Buyers

FILTER / SEARCH BAR:
  Search by name / email / phone | Filter: Status (Active / Suspended / Pending) | Join date range | Sort: Newest / Name / Orders

DATA TABLE:
  Columns (configurable via column picker):
    Avatar + Name | Email | Phone | Account Type | Status Badge | Joined Date | Total Orders | Actions

  Row actions (kebab menu):
    View full profile | Edit details | Suspend account | Unsuspend | Delete | Send notification

USER PROFILE SIDE PANEL (420px drawer):
  Profile photo | Full info
  Activity stats: total orders, spend, avg rating given
  Tabs: Info | Order history | Address book | Activity log
  Danger zone: Suspend / Delete buttons
```

### 3. Seller Management Page

```
APPROVAL QUEUE (top section, collapsible):
  Banner: "X pending seller applications"
  Table: Applicant name | Store name | Submitted date | Documents | Approve / Reject buttons
  Document viewer modal: shows uploaded ID, permit, etc.

ACTIVE SELLERS TABLE:
  Store name + logo | Owner | Status | Orders (30d) | Revenue (30d) | Rating | Commission rate | Actions

SELLER DETAIL PANEL:
  Store info | performance metrics | menu item count
  Commission rate override input (admin can set per-seller)
  Store status toggle (active / suspended)
  Order history for this seller
```

### 4. Rider Management Page

```
APPROVAL QUEUE:
  Pending rider applications table
  Vehicle type | License preview | ID preview | Approve / Reject

ACTIVE RIDERS TABLE:
  Name | Vehicle | Status (Online/Offline) | Today's deliveries | Rating | Payout balance | Actions

LIVE MAP VIEW (toggle button):
  Full-width embedded map
  All online riders shown as animated scooter pins
  Click pin → rider info popup

RIDER DETAIL PANEL:
  Same structure as user panel but with: delivery history, earnings, rating breakdown, vehicle info
```

### 5. Order Management Page

```
GLOBAL ORDERS VIEW (all sellers, all riders):

FILTER BAR:
  Status | Date range | Seller | Rider | Payment method | Amount range

STATS STRIP:
  Today: X total | X pending | X in-progress | X completed | X cancelled

DATA TABLE:
  Order ID | Customer | Seller | Rider | Items | Total | Status | Placed at | Actions

ACTIONS:
  View full order | Reassign rider | Cancel order | Issue refund | Contact parties

ORDER DETAIL MODAL:
  Full breakdown: items, prices, addresses, timeline log
  Timeline: order placed → confirmed → preparing → picked up → delivered (with timestamps)
  Refund section: amount input + reason + confirm
```

### 6. Finance & Revenue Page

```
SUMMARY CARDS:
  Gross Revenue (period) | Platform Commission Earned | Rider Payouts | Pending Disputes

REVENUE BREAKDOWN TABLE:
  Seller name | Orders | Gross sales | Commission % | Commission ₱ | Net to seller | Payout status

COMMISSION SETTINGS (side panel):
  Default commission rate input
  Per-seller overrides table

PAYOUT MANAGEMENT:
  Pending payouts table: seller/rider | amount | due date | Pay Now button
  Batch payout button (select all + confirm)
  Payout history with receipt download

DISPUTE / REFUND TABLE:
  Order ID | Reporter | Issue type | Amount | Status | Opened | Resolve button
  Resolution modal: approve refund / reject + reason
```

### 7. Platform Settings Page

```
TABS: General | Fees | Notifications | Integrations | Feature Flags | Audit Log

GENERAL TAB:
  Platform name | Logo | Favicon | Default city/region | Currency | Language | Timezone

FEES TAB:
  Default delivery fee structure (flat / distance tiers)
  Default commission rate
  Minimum order amount (platform-wide)
  Surge pricing toggle + settings

NOTIFICATIONS TAB:
  Email templates (order confirmed, dispatched, delivered, etc.)
  SMS gateway config (API key input, masked)
  Push notification settings

FEATURE FLAGS TAB:
  Toggles (on/off with descriptions):
    Maintenance Mode | New Seller Registration | New Rider Registration
    Promo System | Loyalty Points | Dark Mode | Guest Checkout

AUDIT LOG TAB:
  Timestamped log of all admin actions: who | what | when | before/after value
  Filterable by admin user, action type, date
```

---

## 🔐 Authentication System

### Login Page

```
LAYOUT: Split screen
  LEFT (55%): Full-bleed food photography with brand overlay, logo, tagline
  RIGHT (45%): Login form, centered

FORM:
  "Welcome back" heading (Playfair 32px)
  Email input
  Password input (show/hide toggle)
  Remember me checkbox
  Forgot password link (right-aligned)
  Login button (full width, primary)
  Divider "or continue with"
  Social buttons: Google | Facebook (outline style, icons)
  "Don't have an account? Sign up" link

FORGOT PASSWORD:
  Email input + "Send reset link" button
  Success state: checkmark animation + "Check your inbox"
```

### Sign Up Flow (Multi-step)

```
STEP 1 — Account Basics:
  Full name | Email | Password (strength indicator) | Confirm password
  "Continue" button

STEP 2 — Choose Account Type:
  4 large radio cards:
    [🛒 I want to order food]         — User/Buyer
    [🏪 I want to sell on Food Hub]   — Seller
    [🛵 I want to deliver orders]     — Rider
  Note: Admin accounts are invitation-only

STEP 3a (User):
  Location / delivery address | Profile photo (optional) | Birthday (optional for loyalty perks)

STEP 3b (Seller):
  Store name | Cuisine type | Store address | Operating hours quick-set | Upload: store logo + business permit + owner ID

STEP 3c (Rider):
  Full name confirmation | Vehicle type (Motorcycle / Bicycle / Car) | Plate number | Upload: Driver's license + vehicle registration photo

STEP 4 — Verification:
  Email OTP (6-digit code) input
  Resend code (30s cooldown)
  Sellers/Riders: "Under review" screen — email notification within 24–48 hrs

STEP 5 — Welcome Screen:
  Animated illustration by account type
  CTA: "Start exploring" (User) / "Set up your store" (Seller) / "Go online" (Rider)
```

---

## 🔔 Notification System

### Triggers by Role

| Account | Trigger | Channel |
|---|---|---|
| User | Order confirmed | In-app + Push + Email |
| User | Order preparing | In-app + Push |
| User | Rider on the way | In-app + Push + SMS |
| User | Order delivered | In-app + Push + Email |
| User | Promo / new restaurant | Push + Email |
| User | Order cancelled + refund | In-app + Push + Email |
| Seller | New order received | In-app + Push + Sound alert |
| Seller | Order cancelled by customer | In-app + Push |
| Seller | New review posted | In-app + Email |
| Seller | Weekly payout processed | Email |
| Rider | New delivery available | In-app + Push + Sound |
| Rider | Order assigned | In-app + Push |
| Rider | Customer message | In-app + Push |
| Rider | Weekly earnings summary | Email |
| Admin | New seller application | In-app + Email |
| Admin | Dispute raised | In-app + Email |
| Admin | System alert / error | In-app + Email |
| Admin | Daily platform summary | Email |

---

## ✨ Motion & Animation Design

```
GLOBAL TRANSITIONS:
  Page transition:    fade + translateY(8px → 0) | 200ms ease-out
  Route change:       opacity 0→1 with skeleton placeholder during load

MICRO-INTERACTIONS:
  Card hover:         scale(1.02) + shadow bump | 150ms ease
  Button press:       scale(0.97) | 100ms ease-in-out
  Toggle switch:      thumb slides 200ms cubic-bezier(0.34,1.56,0.64,1)
  Input focus:        border color + ring expand | 150ms ease
  Star rating:        stars fill left-to-right on hover

LOADING STATES:
  Skeleton screens:   animated shimmer (left-to-right gradient sweep, 1.5s loop)
  Spinner:            Chili Red ring, 360° rotation | 700ms linear loop
  Progress bar:       horizontal, red fill with pulse at leading edge

NOTIFICATIONS / FEEDBACK:
  Toast:              slide in from right (300ms) | auto-dismiss with shrink (200ms)
  Success animation:  checkmark draw-on (SVG stroke, 400ms)
  Error shake:        horizontal shake keyframe (300ms)
  Cart add:           item thumbnail fly-to-cart animation (300ms arc)

MAP ANIMATIONS:
  Rider pin:          smooth position interpolation (ease-in-out, every GPS update)
  Route draw:         path stroke-dashoffset animation on initial load

MODALS:
  Entrance:           backdrop fade + modal scale(0.95→1) + translateY(8→0) | 220ms ease-out
  Exit:               reverse, 150ms ease-in
```

---

## 📱 Responsive Breakpoints

| Breakpoint | Min Width | Key Layout Changes |
|---|---|---|
| Mobile S | 320px | Single column, compact typography, bottom nav |
| Mobile L | 425px | Slightly wider cards, more horizontal padding |
| Tablet | 640px | 2-column grids, larger inputs, collapsed sidebar as icon rail |
| Laptop | 1024px | Full sidebar, 3-column grids, cart side panel appears |
| Desktop | 1280px | Optimal layout, all panels visible |
| Wide | 1440px | Max-width container centered, extra whitespace on sides |
| Ultra-wide | >1920px | Same as 1440px, locked |

---

## 🎨 CSS Design Tokens — Complete Reference

```css
:root {
  /* ─── Brand Colors ─── */
  --color-primary:          #E63946;
  --color-primary-light:    #FDECEA;
  --color-primary-dark:     #B02A35;

  --color-secondary:        #F4A261;
  --color-secondary-light:  #FEF3E2;
  --color-secondary-dark:   #C07A38;

  --color-accent:           #2A9D8F;
  --color-accent-light:     #E0F5F3;
  --color-accent-dark:      #1A6B62;

  /* ─── Backgrounds ─── */
  --color-bg-page:          #FFF8F1;
  --color-bg-card:          #FFFFFF;
  --color-bg-raised:        #FFFFFF;
  --color-bg-overlay:       rgba(26, 26, 46, 0.65);

  /* ─── Text ─── */
  --color-text-primary:     #1A1A2E;
  --color-text-secondary:   #6B7280;
  --color-text-muted:       #9CA3AF;
  --color-text-inverse:     #FFFFFF;
  --color-text-link:        #E63946;

  /* ─── Borders ─── */
  --color-border-default:   #F0E6DC;
  --color-border-strong:    #D6C5B8;
  --color-border-focus:     #E63946;

  /* ─── Role Accents ─── */
  --color-role-admin:       #1D3557;
  --color-role-seller:      #E76F51;
  --color-role-rider:       #457B9D;
  --color-role-user:        #E63946;

  /* ─── Status Colors ─── */
  --color-status-pending:   #6B7280;
  --color-status-confirmed: #92400E;
  --color-status-preparing: #9A3412;
  --color-status-delivery:  #1E40AF;
  --color-status-delivered: #166534;
  --color-status-cancelled: #991B1B;

  /* ─── Typography ─── */
  --font-display:   'Playfair Display', Georgia, serif;
  --font-ui:        'DM Sans', system-ui, sans-serif;
  --font-mono:      'JetBrains Mono', 'Courier New', monospace;

  /* ─── Type Scale ─── */
  --text-xs:   11px;
  --text-sm:   12px;
  --text-base: 14px;
  --text-md:   16px;
  --text-lg:   18px;
  --text-xl:   20px;
  --text-2xl:  28px;
  --text-3xl:  40px;
  --text-4xl:  64px;

  /* ─── Spacing ─── */
  --space-1:   4px;
  --space-2:   8px;
  --space-3:   12px;
  --space-4:   16px;
  --space-5:   20px;
  --space-6:   24px;
  --space-8:   32px;
  --space-10:  40px;
  --space-12:  48px;
  --space-16:  64px;
  --space-24:  96px;

  /* ─── Border Radius ─── */
  --radius-xs:   4px;
  --radius-sm:   8px;
  --radius-md:   12px;
  --radius-lg:   16px;
  --radius-xl:   20px;
  --radius-full: 9999px;

  /* ─── Shadows ─── */
  --shadow-sm:  0 1px 3px rgba(0,0,0,0.08);
  --shadow-md:  0 4px 12px rgba(0,0,0,0.12);
  --shadow-lg:  0 8px 24px rgba(0,0,0,0.16);
  --shadow-xl:  0 16px 48px rgba(0,0,0,0.22);
  --shadow-2xl: 0 24px 64px rgba(0,0,0,0.28);

  /* ─── Transitions ─── */
  --transition-fast:   150ms ease;
  --transition-base:   200ms ease-out;
  --transition-slow:   300ms ease-in-out;

  /* ─── Z-Index Scale ─── */
  --z-base:     1;
  --z-dropdown: 100;
  --z-sticky:   200;
  --z-overlay:  300;
  --z-modal:    400;
  --z-toast:    500;
  --z-tooltip:  600;
}
```

---

## 🛠️ Implementation Stack & Notes

```
FRAMEWORK:
  Next.js 14 (App Router) — for SSR/SSG, SEO, and fast routing
  or Nuxt 3 (Vue 3) — alternative

STYLING:
  Tailwind CSS with full custom design token extension in tailwind.config.js
  CSS Modules for complex component-scoped styles

UI COMPONENTS:
  shadcn/ui or Radix UI (headless, fully styled per design tokens)

ICONS:
  Lucide Icons (outlined) — consistent 20px / 24px sizes

MAPS:
  Google Maps API (rider tracking, address pin)
  or Mapbox GL JS (better customization)

CHARTS / ANALYTICS:
  Recharts (React) — revenue, orders, retention charts
  or Chart.js for simpler charts

STATE MANAGEMENT:
  Zustand — cart state, auth state, active order
  React Query / TanStack Query — server state, caching

REAL-TIME:
  Socket.io — live order status, rider GPS updates, new order alerts

MEDIA / IMAGES:
  Cloudinary — food/restaurant photo upload, auto-resize, WebP conversion
  Next/Image for automatic optimization

AUTHENTICATION:
  NextAuth.js + JWT — multi-role session handling

ACCESSIBILITY:
  WCAG 2.1 AA compliance
  All interactive elements: keyboard navigable
  ARIA labels on all icons and dynamic content
  Focus-visible rings on all focusable elements
  Color contrast: minimum 4.5:1 for body text

PERFORMANCE:
  Route-based code splitting
  Lazy-load all images below the fold
  Virtualized lists for long order/product tables (react-window)
  Service worker for offline shell caching

TESTING:
  Jest + React Testing Library for unit/integration
  Playwright for E2E flows (checkout, order tracking)
```

---

*Food Hub — Complete UI/UX Design Prompt v1.0*  
*Covers: Brand · Colors · Typography · Layout · All 4 Role Dashboards · 25+ Pages · Components · Tokens · Motion · Stack*
