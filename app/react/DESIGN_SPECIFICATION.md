# MemoPin Design Specification

## 📱 Overview
This document contains all design specifications for the MemoPin mobile web application. All measurements are in pixels unless otherwise specified.

---

## 🎨 Color System

### Primary Colors
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Primary Blue | `#007aff` | Primary actions, links, active states |
| Primary Blue Hover | `#0051d5` | Hover state for primary blue |
| Light Blue | `#5ac8fa` | Secondary actions, info states |

### System Colors
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Success Green | `#34c759` | Success messages, confirmations |
| Success Green Dark | `#28a745` | Gradient end for success |
| Warning Orange | `#ff9500` | Warnings, cache actions |
| Warning Orange Dark | `#ff8000` | Gradient end for warnings |
| Error Red | `#ff3b30` | Destructive actions, errors |
| Error Red Dark | `#d32f2f` | Gradient end for errors |
| Purple | `#af52de` | Premium features, highlights |
| Purple Dark | `#9b3fce` | Gradient end for purple |
| Gold | `#ffd700` | Subscription badge |
| Gold Dark | `#ffb700` | Gradient end for gold |
| Cyan | `#32ade6` | Support/contact features |
| Cyan Dark | `#1e96d4` | Gradient end for cyan |

### Accent Colors
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Orange Accent | `#ff6b35` | Most Popular badge start |
| Orange Accent Mid | `#ff8c42` | Most Popular badge middle |
| Orange Accent Light | `#ffa94d` | Most Popular badge end |

### Neutral Colors
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Text Primary | `#1c1c1e` | Primary text, headings |
| Text Secondary | `#3c3c43` | Secondary text, descriptions |
| Text Tertiary | `#8e8e93` | Placeholder, disabled text |
| Text Quaternary | `#c7c7cc` | Borders, separators, icons |
| Background Primary | `#ffffff` | Card backgrounds, modals |
| Background Secondary | `#f2f2f7` | Page backgrounds |
| Background Tertiary | `#e5e5ea` | Hover states, disabled buttons |
| Divider | `rgba(0, 0, 0, 0.06)` | Borders, dividers |

### Overlay Colors
| Color Name | Value | Usage |
|------------|-------|-------|
| Modal Backdrop | `rgba(0, 0, 0, 0.4)` | Modal/dialog backgrounds |
| Hover Overlay | `rgba(0, 0, 0, 0.02)` | Button hover state |
| Active Overlay | `rgba(0, 0, 0, 0.04)` | Button active/pressed state |

---

## ✍️ Typography System

### Font Family
- **Primary Font**: System default (`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`)

### Font Sizes
| Size Name | Pixel Value | Usage |
|-----------|-------------|-------|
| XS | `11px` | Badge text, small labels |
| SM | `12px` | Caption text, fine print |
| Base | `13px` | Small body text, section headers (uppercase) |
| MD | `14px` | Secondary body text |
| LG | `15px` | Primary body text, descriptions |
| XL | `17px` | Large body text, button text, list items |
| 2XL | `20px` | Modal titles, card titles |
| 3XL | `22px` | Page titles, section headers |
| 4XL | `26px` | Pricing numbers |
| 5XL | `30px` | Large pricing numbers (Premium plan) |

### Font Weights
| Weight Name | CSS Value | Numeric Value | Usage |
|-------------|-----------|---------------|-------|
| Regular | `normal` | `400` | Body text |
| Medium | `medium` | `500` | Secondary buttons, labels |
| Semibold | `semibold` | `600` | Primary text, headings |
| Bold | `bold` | `700` | Strong emphasis, plan names |

### Line Heights
- Default body text: `1.5` (150%)
- Headings: `1.2` (120%)
- Relaxed text: `1.625` (use `leading-relaxed` class)

### Text Styles - Common Combinations

#### Headings
```
H1 (Page Title): 17px, Semibold, #1c1c1e
H2 (Section Title): 22px, Bold, #1c1c1e
H3 (Card Title): 20px, Semibold, #1c1c1e
H4 (List Item): 17px, Semibold, #1c1c1e
```

#### Body Text
```
Primary Body: 15px, Regular, #3c3c43
Secondary Body: 14px, Regular, #8e8e93
Small Text: 13px, Regular, #8e8e93
Caption: 12px, Regular, #8e8e93
```

#### Section Headers (Uppercase)
```
13px, Semibold, #8e8e93, uppercase, tracking-wide
```

---

## 📏 Spacing System

### Base Spacing Unit
- Base unit: `4px`
- All spacing should be multiples of 4px

### Common Spacing Values
| Value | Pixels | Usage |
|-------|--------|-------|
| `0.5` | `2px` | Minimal spacing |
| `1` | `4px` | Extra small gaps |
| `2` | `8px` | Small gaps |
| `3` | `12px` | Medium gaps |
| `4` | `16px` | Standard gaps |
| `5` | `20px` | Large gaps |
| `6` | `24px` | Extra large gaps |
| `8` | `32px` | Section spacing |

### Component Spacing

#### Padding (Inside components)
```
Button Padding: 12px vertical, 16px horizontal (py-3, px-4)
Card Padding: 20px (p-5)
Modal Padding: 32px (p-8)
Page Horizontal: 20px (px-5)
```

#### Margin (Between components)
```
Section Margin Bottom: 16px (mb-4)
Card Margin Bottom: 24px (mb-6)
Element Gaps: 12px, 16px (gap-3, gap-4)
```

---

## 🔲 Border Radius System

### Border Radius Values
| Value | Pixels | Usage |
|-------|--------|-------|
| Small | `12px` | Buttons, small cards |
| Medium | `13px` | Large buttons |
| Default | `16px` | Standard cards, inputs |
| Large | `20px` | Large cards, subscription plans |
| XL | `24px` | Modals, dialogs |
| Full | `9999px` | Circular elements (icons, avatars) |

### Component Specific
```
Buttons: 12px (rounded-[12px])
Large Buttons: 13px (rounded-[13px])
Cards: 16px (rounded-[16px])
Large Cards: 20px (rounded-[20px])
Modals: 24px (rounded-[24px])
Avatar/Icon Container: 50% (rounded-full)
Toast/Success Message: 16px (rounded-[16px])
```

---

## 🌟 Shadow System

### Shadow Values
| Shadow Name | CSS Value | Usage |
|-------------|-----------|-------|
| Small | `shadow-sm` | Subtle elevation for cards |
| Medium | `shadow-md` | Standard elevation |
| Large | `shadow-lg` | Important elements, premium cards |
| Extra Large | `shadow-xl` | Modals, overlays |
| 2XL | `shadow-2xl` | Maximum elevation |

### Component Shadows
```
Icon Containers: shadow-sm
Standard Cards: shadow-sm
Buttons (Premium): shadow-md
Hover Buttons: shadow-lg
Modals: shadow-2xl
Toast Messages: shadow-2xl
```

---

## 🎯 Icon System

### Icon Library
- **Library**: Lucide React
- **Installation**: `npm install lucide-react`

### Icon Sizes
| Size Name | Pixels | strokeWidth | Usage |
|-----------|--------|-------------|-------|
| Small | `16px` (w-4, h-4) | `2.5` | Button icons, inline icons |
| Medium | `20px` (w-5, h-5) | `2.5` | Navigation, list items |
| Large | `24px` (w-6, h-6) | `2` or `2.5` | Feature icons |
| XL | `32px` (w-8, h-8) | `2` | Modal icons, avatars |

### Icon Container Sizes
```
Small Container: 32px × 32px (w-8, h-8)
Medium Container: 40px × 40px (w-10, h-10)
Large Container: 48px × 48px (w-12, h-12)
XL Container: 64px × 64px (w-16, h-16)
```

### Common Icons Used
```
ChevronLeft, ChevronRight - Navigation
User - Account/Profile
Crown - Subscription
Database - Storage
HelpCircle - FAQ/Help
LogOut - Sign Out
Trash2 - Delete/Clear
Upload - Submit/Upload
Mail - Email/Contact
Shield - Security
FileText - Documents
MessageCircle - Support
Book - Guide
Check - Success/Confirmation
X - Close
Lock - Security/Privacy
Download - Export
```

---

## 🎭 Component Specifications

### Buttons

#### Primary Button
```
Background: #007aff
Text: #ffffff (white)
Font Size: 17px
Font Weight: Semibold (600)
Padding: 12px vertical, 16px horizontal
Border Radius: 12px
Hover: Background #0051d5
Shadow: shadow-md
```

#### Secondary Button
```
Background: #f2f2f7
Text: #007aff
Font Size: 17px
Font Weight: Medium (500)
Padding: 12px vertical, 16px horizontal
Border Radius: 12px
Hover: Background #e5e5ea
```

#### Destructive Button
```
Background: #ff3b30
Text: #ffffff (white)
Font Size: 17px
Font Weight: Semibold (600)
Padding: 12px vertical, 16px horizontal
Border Radius: 12px
Hover: Background #ff4d42
```

#### Icon Button (Small)
```
Size: 32px × 32px (w-8, h-8)
Background: rgba(0, 0, 0, 0.05)
Border Radius: 50% (rounded-full)
Hover: Background rgba(0, 0, 0, 0.1)
```

### Cards

#### Standard Card
```
Background: #ffffff
Border: 1px solid rgba(0, 0, 0, 0.06)
Border Radius: 16px
Padding: 20px (p-5)
Shadow: shadow-sm
```

#### Large Card
```
Background: #ffffff
Border: 1px solid rgba(0, 0, 0, 0.06)
Border Radius: 20px
Padding: 20px (p-5)
Shadow: shadow-sm
```

#### Subscription Card (Premium)
```
Background: #ffffff
Border: 2px solid #af52de
Border Radius: 20px
Padding: 32px top, 20px sides, 20px bottom
Shadow: shadow-lg
Glow Effect: inset gradient overlay
```

### List Items

#### Standard List Item (Clickable)
```
Padding: 12px vertical, 20px horizontal (py-3, px-5)
Gap: 16px (gap-4)
Border Bottom: 1px solid rgba(0, 0, 0, 0.06)
Hover: Background rgba(0, 0, 0, 0.02)
Active: Background rgba(0, 0, 0, 0.04)

Layout:
- Icon Container (40px × 40px) with gradient
- Text Area (flex-1)
  - Title: 17px, Semibold, #1c1c1e
  - Subtitle: 14px, Regular, #8e8e93
- ChevronRight icon (20px, #c7c7cc)
```

### Modals/Dialogs

#### Modal Container
```
Background: #ffffff
Border Radius: 24px
Padding: 32px (p-8)
Max Width: 384px (max-w-sm)
Shadow: shadow-2xl
Backdrop: rgba(0, 0, 0, 0.4) with backdrop-blur

Layout:
- Close button (top-right, 32px × 32px)
- Icon container (64px × 64px, centered)
- Title: 20px, Semibold, #1c1c1e
- Description: 15px, Regular, #3c3c43
- Button area: 2 buttons with 12px gap
```

### Toast/Success Messages

#### Success Toast
```
Background: #34c759
Text: #ffffff (white)
Font Size: 15px
Font Weight: Semibold (600)
Padding: 16px vertical, 24px horizontal
Border Radius: 16px
Shadow: shadow-2xl
Position: Fixed bottom (96px from bottom)
Animation: Slide in from bottom + fade in
Auto-hide: 2 seconds

Layout:
- Icon (24px × 24px) in rounded container
- Message text
- Gap: 12px
```

### Icon Containers (Gradient)

#### Standard Icon Container
```
Size: 40px × 40px (w-10, h-10)
Border Radius: 50% (rounded-full)
Shadow: shadow-sm
Icon: 20px (w-5, h-5), white color, strokeWidth 2.5

Common Gradients:
- Blue: from-[#5ac8fa] to-[#007aff]
- Green: from-[#34c759] to-[#28a745]
- Orange: from-[#ff9500] to-[#ff8000]
- Red: from-[#ff3b30] to-[#d32f2f]
- Purple: from-[#af52de] to-[#9b3fce]
- Gold: from-[#ffd700] to-[#ffb700]
- Cyan: from-[#32ade6] to-[#1e96d4]
- Gray: from-[#8e8e93] to-[#636366]
```

### Section Headers

#### Uppercase Section Header
```
Font Size: 13px
Font Weight: Semibold (600)
Text Transform: Uppercase
Letter Spacing: Wide (tracking-wide)
Color: #8e8e93
Margin Bottom: 8px
Padding Horizontal: 4px
```

### Progress Bars

#### Credit Usage Bar
```
Container:
- Width: 100%
- Height: 10px (h-2.5)
- Background: #f2f2f7
- Border Radius: 9999px (rounded-full)

Fill:
- Background: Gradient from-[#34c759] to-[#28a745]
- Border Radius: 9999px (rounded-full)
- Transition: All 300ms
- Width: Dynamic (based on percentage)
```

### Badges

#### "Most Popular" Badge
```
Background: Gradient from-[#ff6b35] via-[#ff8c42] to-[#ffa94d]
Text: #ffffff (white)
Font Size: 11px
Font Weight: Bold (700)
Text Transform: Uppercase
Letter Spacing: Wide
Padding: 6px vertical, 16px horizontal
Border Radius: 9999px (rounded-full)
Shadow: shadow-lg
Position: Absolute, top -14px, centered
```

---

## 📐 Layout Specifications

### Page Structure

#### Main Container
```
Height: 100vh (h-full)
Display: Flex column (flex flex-col)
Background: #f2f2f7
```

#### Header
```
Padding: 16px top, 12px bottom, 20px horizontal
Background: #ffffff
Border Bottom: 1px solid rgba(0, 0, 0, 0.06)

Layout:
- Back Button (left)
- Title (center, absolute positioning)
- Optional Action (right)
```

#### Scrollable Content Area
```
Flex: 1 (flex-1)
Overflow Y: Auto (overflow-y-auto)
Padding: 20px horizontal, 96px bottom
Background: #f2f2f7
```

### Responsive Behavior
```
Max Width: 414px (mobile-first design)
Centered on larger screens
All measurements optimized for mobile (375px - 414px width)
```

---

## ✨ Animation & Transitions

### Standard Transitions
```
Default: transition-colors (200ms)
All Properties: transition-all (300ms)
Hover Scale: hover:scale-[1.02]
Active Scale: active:scale-[0.98]
Opacity: transition-opacity
```

### Modal Animations
```
Entry: Fade in + backdrop blur
Duration: 300ms
Easing: Default ease
```

### Toast Animations
```
Entry: slide-in-from-bottom-4 + fade-in
Duration: 300ms
Auto-hide: 2000ms
```

### Button Hover Effects
```
Background gradient: transition duration-500
Scale: hover:scale-[1.02]
Shadow: hover:shadow-lg
Active: active:scale-[0.98]
```

### Loading States
```
Pulse Animation: animate-pulse
Applied to icon containers
No text animation
```

---

## 🎨 Gradient Definitions

### Button Gradients
```
Premium Purple:
  from-[#af52de] via-[#c86dd7] to-[#af52de]
  bg-[length:200%_100%]
  hover:bg-right
  transition duration-500

Ultra Orange:
  from-[#ff9500] via-[#ff8c42] to-[#ff9500]
  bg-[length:200%_100%]
  hover:bg-right
  transition duration-500
```

### Icon Container Gradients
```
See "Icon Containers (Gradient)" section above
All use: bg-gradient-to-br (diagonal gradient)
```

### Badge Gradients
```
Most Popular:
  from-[#ff6b35] via-[#ff8c42] to-[#ffa94d]
  direction: horizontal (to-r)
```

---

## 📱 Specific Page Layouts

### Login/Signup Modal
```
Full Screen Overlay
Background: #ffffff
Padding: 20px
Max Width: None (full width)
Z-index: 50

Components:
- Close button (top-right)
- Logo/Title area
- Input fields (gap-4)
- Primary button
- Link text (#007aff, 15px)
```

### Account & Data Page
```
Sections (gap-16):
1. User Account Card
2. Subscription (with section header)
3. Data Management (with section header)
4. Help & Support (with section header)
5. App Version (centered, small text)

Each section has 8px gap between header and content
```

### Subscription Page
```
Layout:
- Page title (centered)
- Current Plan section
- Plans section with cards (gap-16)
- Pricing info card
- Bottom message

Card spacing: 16px between cards
Section dividers: 1px line with centered text
```

### Clear Cache Page
```
Layout:
- Total cache card (large)
- Select all/deselect all row
- Cache items list
- Clear button
- Info message

List items: Checkboxes (20px) on right side
Selection color: #007aff
```

---

## 🔐 Interactive States

### Hover States
```
Buttons: Darker background color
List Items: Background rgba(0, 0, 0, 0.02)
Scale Effects: scale-[1.02]
Opacity: opacity-70 (for text links)
```

### Active/Pressed States
```
Buttons: scale-[0.98]
List Items: Background rgba(0, 0, 0, 0.04)
```

### Disabled States
```
Background: #e5e5ea
Text: #8e8e93
Opacity: opacity-50
Cursor: not-allowed
```

### Focus States
```
Follow browser default focus rings
Ensure keyboard accessibility
```

---

## 📝 Form Elements

### Input Fields
```
Height: 48px
Padding: 12px horizontal
Border: 1px solid rgba(0, 0, 0, 0.1)
Border Radius: 12px
Font Size: 17px
Background: #ffffff

Focus:
- Border: 2px solid #007aff
- Outline: None

Placeholder:
- Color: #8e8e93
```

### Checkboxes
```
Size: 20px × 20px (w-5, h-5)
Border: 2px solid #c7c7cc
Border Radius: 50% (rounded-full)
Background (unchecked): #ffffff
Background (checked): #007aff
Border (checked): #007aff

Checkmark:
- Size: 12px
- Color: #ffffff
- strokeWidth: 3
```

---

## 🎯 Special Effects

### Backdrop Blur
```
Modal backdrop: backdrop-blur-sm
Creates iOS-style frosted glass effect
```

### Glow Effects (Premium Cards)
```
Outer glow:
  position: absolute
  inset: 0
  border-radius: match parent
  background: gradient
  blur: xl
  z-index: -10
  opacity: 20%
```

### Overlay Gradient
```
Premium card overlay:
  position: absolute
  inset: 0
  background: gradient from-[color]/5 to-[color]/5
  pointer-events: none
  border-radius: match parent
```

---

## 📊 Z-Index Scale
```
Base Content: z-0
Nav Bar: z-10
Modals: z-50
Toasts: z-50
Backdrop: z-50
Dev Panel: z-50
```

---

## 🚀 Implementation Notes

### Tailwind CSS Version
- Using Tailwind CSS v4.0
- Custom colors defined in theme.css
- No tailwind.config.js needed

### Font Loading
- System fonts (no custom font files needed)
- Fast loading, native appearance

### Icons
```javascript
import { IconName } from 'lucide-react';

// Usage
<IconName className="w-5 h-5" strokeWidth={2.5} />
```

### Responsive Design
- Mobile-first approach
- Target: 375px - 414px (iPhone sizes)
- All units in px (absolute sizing for consistency)

### Browser Support
- Modern browsers (Chrome, Safari, Firefox, Edge)
- iOS Safari optimization
- No IE11 support needed

---

## 📦 Component Checklist for Developers

When implementing each component, ensure:

- ✅ Correct colors from color system
- ✅ Correct font sizes and weights
- ✅ Proper spacing (padding/margin)
- ✅ Border radius values
- ✅ Shadow effects
- ✅ Hover/active states
- ✅ Transitions/animations
- ✅ Icon sizes and strokeWidth
- ✅ Accessibility (keyboard navigation, ARIA labels)
- ✅ Responsive behavior

---

## 🎨 ADHD-Friendly Design Principles

### Applied in This Design
1. **Soft Color Palette** - No harsh contrasts, easy on the eyes
2. **Clear Visual Hierarchy** - Distinct sections with headers
3. **Obvious Grouping** - Cards and borders define related content
4. **Consistent Spacing** - Predictable rhythm reduces cognitive load
5. **Large Touch Targets** - Minimum 44px for interactive elements
6. **Clear Feedback** - Immediate visual response to interactions
7. **Minimal Distractions** - Clean, focused interface
8. **Progress Indicators** - Clear loading and success states

---

## 📞 Developer Support

### Questions About This Spec?
If you need clarification on any design decision:
1. Check the code implementation for exact values
2. Use browser inspector to verify measurements
3. Refer to component sections for complete specifications

### Design Tokens Location
All design values are defined in:
- `/src/styles/theme.css` - CSS variables and base styles
- Component files - Tailwind utility classes

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-19  
**Design System**: MemoPin ADHD-Friendly Mobile UI  
**Platform**: Mobile Web (iOS-style)