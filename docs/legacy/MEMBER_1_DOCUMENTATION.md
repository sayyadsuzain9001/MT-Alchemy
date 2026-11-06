# MT Alchemy Member 1 UI/UX Documentation

## Scope

This Flutter prototype implements the Member 1 corporate website scope:

- Home
- About
- Services
- Individual Coaching
- Organizations
- Corporate Programmes
- Impact Stories
- Insights
- Contact
- Top-level navigation

The assignment's 27+ pages describe the whole three-member platform. LMS, store, learner, employer, trainer and admin screens belong to the other members. They are not duplicated here.

## Sitemap

```text
Home
├── About
├── Services
│   └── Individual Coaching
├── Organizations
├── Corporate Programmes
├── Impact Stories
├── Insights
└── Contact
```

The sitemap is documentation of the information architecture. It is not implemented as a user-facing system page.

The top-level navigation also includes Upskilling, Store, Login, Register and Cart as team handoff destinations. Their full LMS, authentication and e-commerce interfaces remain assigned to Members 2 and 3 and can replace the handoff screens during integration.

## Flutter Requirement Evidence

- `Scaffold`: `SiteShell` provides the app bar, responsive drawer and page body for every route.
- `Container`: used for hero sections, cards, callouts, metadata panels and the footer.
- `Form`: the Contact page uses `Form`, `TextFormField`, `DropdownButtonFormField` and validation.
- `Widget`: reusable widgets include `SiteShell`, `PageWidth`, `SectionTitle`, `InfoCard`, `ResponsiveGrid`, `PhotoCard` and `SiteFooter`.
- Navigation: all eight Member 1 pages are connected through named routes, desktop navigation and a mobile drawer.

## Design System

- Deep Blue: `#16105B`
- Royal Blue: `#2412B8`
- Soft Yellow: `#FFD45A`
- Purple: `#7655B7`
- Warm background: `#FFFBF2`

The layout adapts for desktop, tablet and mobile widths. Mock content is used because backend, Firebase and real enquiry submission are outside Checkpoint 1.
