# 油耗记录 - Master Design System

# 油耗记录 - Design System

**Query:** motorcycle fuel consumption tracker personal utility mobile app dark minimal

## Product Pattern

- **Type:** Weather
- **Category:** utility
- **Description:** Current conditions and forecasts
- **Style Recommendation:** Dynamic backgrounds reflecting conditions

## Style Direction

- **Style:** Dark Mode
- **Description:** Dark backgrounds with light text and accent colors
- **Effects:** Deep blacks (#000 or #121212); elevated surfaces; desaturated colors
- **Typography Direction:** Variable font weights for hierarchy; slightly increased line-height
- **Anti-Patterns:** Pure black text on pure white (inverse); forgetting contrast

## Color Palette

### Primary: Charcoal Dark
- Light: #374151,#1F2937,#111827
- Dark: #6B7280,#4B5563,#374151
- Contrast: 7.2:1
- Description: Charcoal for sophisticated dark interfaces

### Secondary: Pearl Light
- Light: #F3F4F6,#E5E7EB,#D1D5DB
- Dark: #F9FAFB,#F3F4F6,#E5E7EB
- Contrast: 4.5:1

## Typography

- **Heading Font:** Poppins
- **Body Font:** Lato
- **Category:** sans_sans
- **Description:** Approachable geometric for consumer apps
- **Weights:** 400;500;600;700
- **URL:** https://fonts.google.com/specimen/Poppins

## Landing Page Structure

1. **Navigation** (CRITICAL)
   - Purpose: Persistent access to key pages
   - Key Elements: Logo; nav links; CTA button; mobile hamburger; search
   - CTA Strategy: Secondary CTA in nav

## Reasoning & Validation

- **style_to_color:** recommend Indigo Tech or Charcoal Dark or Cyan Electric
  - Reasoning: Dark mode needs colors with sufficient contrast on dark backgrounds; avoid pure black

- **tone_to_typography:** recommend Inter + Inter or Work Sans + Work Sans
  - Reasoning: Professional tones need highly legible neutral typefaces that do not distract

## Anti-Patterns to Avoid

- Pure black text on pure white (inverse); forgetting contrast
- Mixing multiple icon styles (filled + outline)
- Emoji as structural icons
- Hardcoded hex values instead of semantic tokens
- Horizontal scroll on mobile
- Touch targets < 44pt


## Page Overrides
Place page-specific deviations in `pages/` folder.
