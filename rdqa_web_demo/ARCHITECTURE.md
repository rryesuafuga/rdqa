# RDQA Demo Website Architecture

## Tiko RDQA Consultancy — Demo-Sell-Build Website

**Consultancy:** Routine Data Quality Audits (RDQAs) for Tiko Africa — Uganda Programme
**Consultants:** Paul Mubiri & Raymond R. Wayesu
**Date:** February 2026
**Purpose:** Professional demo website to showcase the RDQA consultancy capabilities, methodology, and simulated deliverables to prospective clients — following the "demo-sell-build" approach.

---

## 1. Strategic Intent (Demo-Sell-Build)

This website is a **demo** — not the final product. It is designed to:

1. **Earn Attention** — A bold unique value proposition that speaks directly to organisations like Tiko Africa needing independent, rigorous data quality assurance.
2. **Earn Trust** — Interactive, media-quality simulated visualisations demonstrating what the RDQA deliverables look like in practice (Verification Factor dashboards, spider charts, facility scorecards, root cause breakdowns).
3. **Drive Action** — Clear call-to-action for prospective clients to engage the consultancy team.

> *"If you can sell the demo, why even build the product?"* — Ash Maurya, Demo-Sell-Build Framework

---

## 2. Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Framework** | Vanilla HTML5 + CSS3 + ES Modules | Zero-dependency, fast, Vercel-ready static site |
| **Visualisations** | D3.js v7 | Verification Factor gauges, bar charts, spider/radar charts, Sankey diagrams, geographic heatmaps |
| **Animations** | GSAP (GreenSock) v3 | Scroll-triggered animations, number counters, section reveals, parallax effects |
| **Styling** | Modern CSS (Grid, Flexbox, Custom Properties, `@media prefers-color-scheme`) | Professional responsive layout with dark/light mode |
| **Accessibility** | ColorBrewer 2.0 colorblind-safe palettes | All visualisations use 8-class qualitative palette safe for deuteranopia, protanopia, and tritanopia |
| **Icons** | Inline SVG | No external icon dependencies |
| **Fonts** | System font stack + Google Fonts (Inter, Source Serif Pro) | Professional typography |
| **Deployment** | Vercel (Static) | Zero-config static deployment |

---

## 3. Colour System — Colorblind-Safe Design

All visualisations use the **ColorBrewer "Set2" + "Dark2"** qualitative palette, which is safe for all three major types of colour vision deficiency:

| Token | Hex | Usage |
|-------|-----|-------|
| `--cb-teal` | `#66C2A5` | Acceptable VF range (90-110%) |
| `--cb-orange` | `#FC8D62` | Over-reporting flag (<90% VF) |
| `--cb-purple` | `#8DA0CB` | Under-reporting flag (>110% VF) |
| `--cb-pink` | `#E78AC3` | Root Cause: Human Factors |
| `--cb-green` | `#A6D854` | Root Cause: Systems/Process |
| `--cb-yellow` | `#FFD92F` | Root Cause: Supply/Resources |
| `--cb-brown` | `#E5C494` | Root Cause: Intentional |
| `--cb-grey` | `#B3B3B3` | Root Cause: Contextual/External |

Additionally:
- All charts include **pattern fills** (stripes, dots, crosshatch) as a secondary encoding alongside colour.
- All data points include **text labels** and **tooltips** so information is never conveyed by colour alone.
- Contrast ratios meet WCAG 2.1 AA standards (4.5:1 minimum for text).

---

## 4. Site Architecture — Page Sections

The website is a **single-page application** with smooth-scrolling sections:

```
index.html
├── Section 1: Hero / UVP
├── Section 2: The Challenge (Problem Statement)
├── Section 3: Our Approach (Three-Way Triangulation)
├── Section 4: Live Demo — Verification Factor Dashboard
├── Section 5: Live Demo — Facility Scorecard Spider Charts
├── Section 6: Live Demo — Root Cause Analysis
├── Section 7: Live Demo — Monthly RDQA Timeline
├── Section 8: Live Demo — Kampala vs Wakiso Comparison
├── Section 9: Team Credentials
├── Section 10: Frameworks & Methodology
├── Section 11: Deliverables Overview
├── Section 12: Call to Action / Contact
└── Footer
```

---

## 5. Section Specifications

### 5.1 Hero Section
- **Headline:** "Data You Can Trust. Decisions You Can Defend."
- **Subheadline:** "Independent Routine Data Quality Audits for Tiko Africa — Kampala & Wakiso Districts"
- **Background:** Animated particle network (GSAP) representing data connections
- **Key Stats Counter:** (GSAP ScrollTrigger) 23+ years combined experience | 54 facilities | 3 frameworks | 296 mobilisers
- **CTA Button:** "See Our RDQA Demo" (scrolls to Section 4)

### 5.2 The Challenge
- **Visual:** Animated split diagram showing Tiko Platform (digital) vs HMIS Registers (paper) running in parallel with discrepancy indicators
- **Copy:** Explains the core challenge — digital vs paper-based systems creating data gaps
- **D3.js Animation:** Two parallel data streams flowing with highlighted discrepancy points

### 5.3 Our Approach — Three-Way Triangulation
- **D3.js Sankey Diagram:** Interactive flow showing data from three sources (Tiko Platform, Facility Registers, National DHIS2) converging into verified, reconciled data
- **Hover interactions:** Each node shows description and verification method
- **Pattern fills** for colorblind accessibility

### 5.4 Verification Factor Dashboard (Primary Demo)
- **D3.js Interactive Bar Chart:** Simulated Verification Factors for 12 health facilities
- **Tolerance Band:** Shaded 90-110% acceptable range
- **Colour coding:** Teal (acceptable), Orange (over-reporting <90%), Purple (under-reporting >110%)
- **Interactivity:** Click facility to drill into indicator-level VFs
- **Animated counters:** Show percentage of facilities within tolerance
- **Indicators:** Family Planning, HIV Testing, ANC Visits, Immunisations, SGBV Referrals

### 5.5 Facility Scorecard — Spider/Radar Charts
- **D3.js Radar Chart:** Five-axis systems assessment (M&E Structure, Data Collection, Indicator Definitions, Data Management, Data Use)
- **Toggle:** Switch between individual facilities to compare scores
- **Pattern fills:** Each axis uses distinct pattern
- **Baseline overlay:** Show before/after RDQA improvement trajectory

### 5.6 Root Cause Analysis Breakdown
- **D3.js Sunburst/Donut Chart:** Proportional breakdown of root causes across all facilities
- **Categories:** Human Factors, Systems/Process, Supply/Resources, Intentional, Contextual/External
- **Drill-down:** Click category to see specific examples
- **Animated transitions** between views

### 5.7 Monthly RDQA Timeline
- **D3.js + GSAP Timeline:** Interactive Gantt-style chart showing the 25-day monthly cycle
- **Three phases:** Pre-Visit (Days 1-3), On-Site (Days 4-18), Analysis & Reporting (Days 19-25)
- **Scroll-triggered animation:** Phases animate in sequence as user scrolls

### 5.8 Kampala vs Wakiso Comparison
- **D3.js Grouped Bar Chart:** Side-by-side comparison of VFs across the two districts
- **Interactive toggle:** Switch between indicators
- **Animated transitions** between datasets
- **Summary statistics** panel

### 5.9 Team Credentials
- **Professional cards** for Paul Mubiri and Raymond R. Wayesu
- **GSAP reveal animation** on scroll
- **Key stats:** 23+ years combined, 25+ publications, expertise in DHIS2, R, Python, STATA
- **Past performance highlights** with organisation logos

### 5.10 Frameworks & Methodology
- **Three-column layout** with animated icons:
  1. MEASURE Evaluation RDQA Tool
  2. WHO Data Quality Review Toolkit
  3. Uganda MoH HMIS Guidelines
- **GSAP stagger animation** on scroll entry

### 5.11 Deliverables Overview
- **Interactive cards** showing each deliverable with format and frequency
- **Deliverables:** Inception Report, Monthly Cleaned Datasets, Individual Facility Reports, Action Point Tracker, Quarterly Data Review Reports, Strategic Insights Reports

### 5.12 Call to Action
- **Headline:** "Ready to Strengthen Your Data Quality?"
- **Contact details** for both consultants
- **Email link** and submission reference
- **"Request a Proposal" button**

---

## 6. File Structure

```
rdqa_web_demo/
├── index.html                    # Main single-page application
├── css/
│   ├── main.css                  # Core styles, layout, typography
│   ├── variables.css             # CSS custom properties, colorblind-safe palette
│   ├── animations.css            # GSAP-triggered animation classes
│   └── responsive.css            # Media queries for mobile/tablet/desktop
├── js/
│   ├── main.js                   # App initialisation, scroll handling, navigation
│   ├── data.js                   # Simulated RDQA data (VFs, scores, root causes)
│   ├── charts/
│   │   ├── verification-factor.js  # D3.js VF bar chart with tolerance band
│   │   ├── spider-chart.js         # D3.js radar/spider chart for facility scores
│   │   ├── root-cause.js           # D3.js sunburst/donut chart
│   │   ├── sankey.js               # D3.js Sankey diagram for triangulation
│   │   ├── timeline.js             # D3.js + GSAP Gantt timeline
│   │   └── district-compare.js     # D3.js grouped bar chart
│   └── animations/
│       ├── hero.js                 # Particle network background
│       ├── counters.js             # Number counter animations
│       └── scroll-reveals.js       # ScrollTrigger section reveals
├── assets/
│   └── favicon.svg               # Site favicon
├── vercel.json                   # Vercel deployment configuration
├── package.json                  # Project metadata (no build dependencies)
├── ARCHITECTURE.md               # This document
└── ARCHITECTURE.docx             # This document (Word format)
```

---

## 7. Simulated Data Strategy

All visualisations use **realistic but simulated data** designed to demonstrate the RDQA methodology. The data mirrors what actual RDQA outputs would look like:

- **12 health facilities** across Kampala (6) and Wakiso (6) districts
- **5 health indicators:** Family Planning, HIV Testing Services, ANC First Visit, Immunisation (DPT3), SGBV Referrals
- **Verification Factors** ranging from 72% to 118% to show realistic variation
- **Systems Assessment Scores** across 5 M&E functional areas (1-5 Likert scale)
- **Root Cause Distribution** reflecting real-world patterns from Uganda health sector
- **Monthly trend data** for March-December 2026 projection

---

## 8. Performance & Accessibility

- **Lighthouse Target:** 95+ on Performance, 100 on Accessibility
- **Core Web Vitals:** LCP < 2.5s, FID < 100ms, CLS < 0.1
- **Progressive Enhancement:** Site is fully readable without JavaScript; charts enhance the experience
- **ARIA Labels:** All interactive elements have proper ARIA attributes
- **Keyboard Navigation:** All interactive chart elements are keyboard-accessible
- **Screen Reader Support:** Chart data available as accessible tables with `aria-describedby`
- **Reduced Motion:** Respects `prefers-reduced-motion` media query

---

## 9. Vercel Deployment

- **Type:** Static site (no server-side rendering needed)
- **Config:** `vercel.json` with proper caching headers for static assets
- **CDN Libraries:** D3.js and GSAP loaded from CDN with SRI integrity hashes
- **Custom Domain:** Ready for custom domain configuration

---

## 10. Demo-Sell-Build Alignment

| Demo-Sell-Build Element | Website Implementation |
|------------------------|----------------------|
| **Unique Value Proposition** | Hero section headline: "Data You Can Trust. Decisions You Can Defend." |
| **Demo (Earn Trust)** | 5 interactive D3.js visualisation sections showing simulated RDQA outputs |
| **Call to Action** | Contact section with direct email and "Request a Proposal" button |
| **Urgency/Scarcity** | "March 2026 Start Date" — limited consultancy capacity for Q1 |
| **Social Proof** | Team credentials, 25+ publications, past performance with PTBi, MGIC, UVRI |
| **Three Core Features** | Three-Way Triangulation, Facility Scorecards, Root Cause Framework |

---

*Architecture Document — Tiko RDQA Demo Website*
*Paul Mubiri & Raymond R. Wayesu | February 2026*
