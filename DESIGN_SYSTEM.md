# Design System Rules: Material Design 3 (M3)

Adhere strictly to the Material Design 3 specification for all UI implementations.
Avoid generic AI styles (arbitrary drop shadows, random gradient cards, inconsistent padding).

---

## 1. Color System & Semantic Roles
Do NOT use hardcoded arbitrary hex codes in components. Always map colors to M3 semantic roles:

- **Primary / On Primary**: Key high-emphasis actions (Filled Button, Active Tab).
- **Secondary / On Secondary**: Less prominent actions, filter chips.
- **Tertiary / On Tertiary**: Accent elements, contrasting highlights (use sparingly).
- **Surface / On Surface**: App backgrounds, sheet surfaces, text colors (`on-surface` for primary text, `on-surface-variant` for secondary).
- **Surface Container Levels** (Crucial: Replace custom gray backgrounds with these):
  - `Surface Container Lowest` (Lowest emphasis/pure white or deepest dark)
  - `Surface Container Low`
  - `Surface Container` (Default card / dialog surface)
  - `Surface Container High`
  - `Surface Container Highest` (Input fields, search bars)
- **Outline & Outline Variant**: 1px borders (`outline` for inputs/borders, `outline-variant` for dividers).

---

## 2. Elevation & Tonal Surface (Strict Rule)
- **NO Heavy Drop Shadows**: In M3, elevation is represented primarily by **Surface Tint** (layering Surface Container levels) rather than dark drop shadows.
- Level 0 (Flat): No shadow (`elevation-0`).
- Level 1 (Card/List item): Subtle elevation or 1px `outline-variant` border.
- Level 2–3 (Dialogs, Navigation Bars, Menus).
- Level 4–5 (Modals, Pickers, FAB when hovered).

---

## 3. Shape / Corner Radius Scale
Do NOT use arbitrary `rounded-[13px]`. Use ONLY the M3 shape scale:

| Token | Radius | Allowed Components |
| :--- | :--- | :--- |
| `None` | `0dp / 0px` | Fullscreen containers, dividers |
| `Extra Small` | `4dp / 4px` | Snackbars, small tooltips |
| `Small` | `8dp / 8px` | Chips, compact text fields |
| `Medium` | `12dp / 12px` | Standard cards, small dialogs |
| `Large` | `16dp / 16px` | Floating Action Button (FAB), Navigation Drawer |
| `Extra Large` | `28dp / 28px` | Large dialogs, Time pickers, Search View |
| `Full` | `9999px` | Circular buttons, Pill buttons, Badges |

---

## 4. Typography Scale & Hierarchy
Do NOT mix random font sizes. Use M3 standard role hierarchy:

- **Display (Large / Medium / Small)**: `57sp` / `45sp` / `36sp` (Hero, landing splash only)
- **Headline (Large / Medium / Small)**: `32sp` / `28sp` / `24sp` (Page titles, Dialog titles)
- **Title (Large / Medium / Small)**: `22sp` / `16sp` / `14sp` (Card titles, App bar headers)
- **Body (Large / Medium / Small)**: `16sp` / `14sp` / `12sp` (Main readable content)
- **Label (Large / Medium / Small)**: `14sp` / `12sp` / `11sp` (Buttons, Chips, Captions, Nav labels)
- **Capitalization Rule**: Always use **Sentence case** for titles, buttons, and headings. NEVER use Title Case or ALL CAPS.

---

## 5. Spacing & Touch Targets (8dp Grid)
- **Base Grid**: Spacing must be multiples of 8 (`8dp`, `16dp`, `24dp`, `32dp`). Use `4dp` only for micro-alignments (icon-to-text gap).
- **Screen Padding**: Mobile screen horizontal padding is strictly `16dp`.
- **Minimum Touch Target**: Every interactive element (buttons, icons, checkboxes) MUST have an accessible touch target of at least **48dp × 48dp**, even if the visual element is smaller.

---

## 6. Component Selection Guide
- **Buttons**:
  - `Filled Button`: Only ONE per screen/section for the primary action.
  - `Tonal Button` / `Outlined Button`: For secondary actions.
  - `Text Button`: For tertiary/dismissive actions ("Cancel", "Learn more").
- **Cards**:
  - `Elevated Card`: Has subtle elevation.
  - `Filled Card`: Uses `surface-container-highest` background without border.
  - `Outlined Card`: Uses `surface` background with a 1px `outline-variant` border (preferred for clean modern looks).
- **Navigation**:
  - Top: `CenterAlignedTopAppBar` or `SmallTopAppBar`.
  - Bottom: `NavigationBar` (3 to 5 destinations with pill-shaped active indicator).

---

## 7. Anti-Pattern / Blacklist (Never Do This)
- ❌ Do NOT use generic purple/blue tech-style gradients on cards or backgrounds.
- ❌ Do NOT apply blur effects (Glassmorphism/backdrop-blur) unless explicitly requested.
- ❌ Do NOT use tiny text below `11sp`.
- ❌ Do NOT use pure black (`#000000`) for text on light mode; use `On Surface` (`#1D1B20` approx).
