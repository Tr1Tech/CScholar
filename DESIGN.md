# CScholar — System Architecture & Page Map

**What this is:** architecture source-of-truth for rebuilding CScholar screens. §8 now defines the full Soft UI v4 token set (color, type, radius, elevation, motion); mobile is the source of truth and desktop aliases it. Keep the routes, roles, data contracts, and invariants below.

**Stack:** Flutter (web + mobile) + FastAPI + PostgreSQL + pgvector + Sentence Transformers `all-MiniLM-L6-v2` (384-d) + PyMuPDF. Scope: CEIT only.

**Interface Design (Figma) Goal: Clickable prototype** — every route below maps to one Figma frame; all taps, filters, tabs, and role redirects must be wired as Figma prototype connections so the full flows in §3 are clickable end-to-end (login → dashboard → repository → detail → saved/profile, admin curate loop, faculty submit loop).

## 1. Roles & Access

| Role | Lands on | Can access |
|------|----------|------------|
| `student` | `/student/dashboard` | `/student/dashboard`, `/repository`, `/thesis/:id`, `/saved`, `/profile` |
| `faculty` | `/faculty/dashboard` | `/faculty/*` + `/thesis/:id` (role-aware). Blocked from `/admin/*`, `/student/*`, `/repository`, `/saved`, `/profile` |
| `admin` | `/admin/dashboard` | `/admin/*` + `/thesis/:id` (role-aware). Blocked from `/student/*`, `/faculty/*`, `/repository`, `/saved`, `/profile` |

- Unauthenticated: only `/login`, `/register` (plus dev-only `/design-lab`). Everything else redirects to `/login`.
- Auth state restores via `loadToken()` on startup; redirect waits for `isLoading == false`.
- Invalid `/thesis/:bad-id` renders inline error + Back button. Unknown routes render `/:unmatched` 404 + Back to Sign In.

## 2. Routes — Full Inventory (20 screens)

### Public
| Route | File | Purpose |
|-------|------|---------|
| `/login` | `screens/auth/login_screen.dart` | Email + password sign-in. Validates, calls `authProvider.login()`, routes by `role`. Forgot-password dialog (admin-handled message). Remember-me toggle. |
| `/register` | `screens/auth/register_screen.dart` | Student self-registration: name, student ID, email, program dropdown (live `programsProvider`), password x2. On success → `/student/dashboard`. |

### Student (shell: `StudentLayout` idx 0-3 + `CScholarFooter`)
| Route | File | Purpose |
|-------|------|---------|
| `/student/dashboard` | `screens/student/student_dashboard_screen.dart` | Home. Greeting banner (time-of-day + username + date), 4 metric cards (Published Studies, CEIT Programs, Academic Years, Your Saved), Recent Studies list (latest 4, tap → detail), Recommended for You (semantic recs from most recent record, tap → detail with score). |
| `/repository?q&mode` | `screens/repository/repository_screen.dart` | Core discovery. `?q=` initial query, `?mode=semantic` preselects semantic search. Control header (title, search field with 450ms debounce, quick topics: Machine Learning / IoT / Web System / Mobile App, filters: type + program + year + category + keyword + sort). Results list (`ResultCard`) + AI rail (`RecRail`, top 4 semantic matches). Mobile filters in bottom sheet. |
| `/thesis/:id` + `extra: double?` | `screens/thesis/thesis_detail_screen.dart` | Role-aware detail (`homeRoute`/`listRoute` switch per role). Hero banner, breadcrumbs (Home / List / Title), metadata rows (authors, program, year, adviser, category, type), View PDF (token-as-`?token=`), Save toggle (student only), Share + Cite (APA) buttons, semantic match meter (only when `extra` score passed), keywords, Related research (same `result` stagger as every list). |
| `/saved` | `screens/student/saved_theses_screen.dart` | Bookmarked studies. Tabs: All / Thesis / Capstone filter. Row: cover tile, title, program + year, View + unsave toggle (removal re-forms keyed list). Empty state → Browse Repository. |
| `/profile` | `screens/student/profile_screen.dart` | Identity card (avatar hero target — shell must set `heroAvatar: false` here, gradient accent bar, username + email + role badge + member-since/active pills), Account Information rows, Saved Studies preview (top 3 + View All Saved), Recent Searches (device-persisted, tap to re-run, per-row remove + Clear). Edit Profile = snackbar stub. |

### Admin (shell: `CScholarShell` + `AdminSidebar` + `AdminTopbar`)
| Route | File | Purpose |
|-------|------|---------|
| `/admin/dashboard` | `screens/admin/admin_dashboard_screen.dart` | Ops overview. 4 KPIs (STUDIES/PROGRAMS/USERS/SEARCHES + weekly deltas), Repository Analytics (status bars: published/approved/draft/archived from `thesisListProvider(showAll)`), Recent Activity feed (live audit, tight stagger), Quick Management tiles (Add Thesis / Manage Users / Programs & Tags). |
| `/admin/thesis/management` | `screens/admin/admin_thesis_management_screen.dart` | Full table (Title 470px + Program + Year + Status chip + Actions: status dropdown draft/approved/published/archived, View, Edit, Delete w/ confirm dialog). Live `adminThesisSearchProvider` filter. `DataTable` rows enter with card (no row stagger). |
| `/admin/thesis/new` | `screens/admin/admin_add_edit_thesis_screen.dart` | Create (status forced `published`). Title, abstract, program/year/type/adviser pickers, authors multi-chip picker, primary category + semicolon keywords, PDF upload (`uploadApi`, 50MB, filename/size shown, remove). Duplicate-check dialog on 409 (`parseDuplicateCandidates` → confirm → retry with `confirmDuplicate`). |
| `/admin/thesis/:id/edit` | same file (`thesisId`) | Edit existing. Prefills all fields post-frame. Same validation. |
| `/admin/programs` | `screens/admin/admin_programs_screen.dart` | Taxonomy CRUD in 3 tabs: Programs / Academic Years / Categories. Each row: avatar/icon + name + sublabel + edit dialog. Add/Edit via `GlassDialog` + `NeumorphField`s. Mobile: `TabBar` in `AppBar` + FAB. |
| `/admin/users` | `screens/admin/admin_user_management_screen.dart` | Accounts table (Name + Email + RoleChip + ActiveChip + Edit / activate-toggle). `NeumorphSegmented` role filter (All/Student/Faculty/Admin). Add/Edit dialogs (username, email, password min-6, role select). Cannot deactivate self or remove own admin. Mobile: card list. |
| `/admin/settings` | `screens/admin/admin_settings_screen.dart` | Device-persisted (`SharedPreferences` `settings_*`): site name/desc/contact/maxResults fields + toggles (semantic, recommendations, autoArchive, publicSearch). Save button real. Mobile body = stub text. |

### Faculty (shell: `CScholarShell`/`ScrollVeil` + `FacultySidebar` + `FacultyTopbar`)
| Route | File | Purpose |
|-------|------|---------|
| `/faculty/dashboard` | `screens/faculty/faculty_dashboard_screen.dart` | Advisee overview. 4 KPIs (ADVISEES/MY THESES/PROGRAMS/REVIEWS), Recent Activity panel, My Advisees count panel. Same grid + stagger as admin dashboard. |
| `/faculty/theses` | `screens/faculty/faculty_theses_screen.dart` | Own advised theses. `ClayChip` status filter (All/Draft/Approved/Published/Archived). Row: title + program/year/authors + status chip + View (+ Edit/Delete if own draft). Delete confirm dialog. `RefreshIndicator` on `facultyThesesProvider`. |
| `/faculty/thesis/new` | `screens/faculty/faculty_thesis_form_screen.dart` | Submit draft (backend forces `draft` regardless). Same fields as admin form minus adviser picker (submitter = adviser, locked row). Authors + categories via multi-pick dialogs. PDF attach (create: carried into payload; edit: server-linked immediately). |
| `/faculty/thesis/:id/edit` | same file (`thesisId`) | Edit own draft only. Non-editable (non-draft or others') → `EmptyState` lock message. |
| `/faculty/students` | `screens/faculty/faculty_students_screen.dart` | Advisee roster (search + counts). One short row per advisee: initials avatar, name, program, study count. Tap opens a dialog listing every supervised study (title, status, year) with a View action. |
| `/faculty/analytics` | `screens/faculty/faculty_analytics_screen.dart` | Supervised breakdown: By Status bars (uses `statusFill`, chart draws 120ms after card), By Program counts, By Academic Year counts. |
| `/faculty/settings` | `screens/faculty/faculty_settings_screen.dart` | Profile card (avatar + username + email + role badge + info rows) + Session card (Copy session token for API debugging + Log Out → `/login`). |

### Dev (stripped from release)
| Route | File | Purpose |
|-------|------|---------|
| `/design-lab` | `screens/design_lab_screen.dart` | Component catalog only. Never link from app flows. |

## 3. Navigation Graph (user flows)

1. **Discover → Filter → Detail:** dashboard or `/repository` → search/debounce/filter pills → `ResultCard` tap → `/thesis/:id` → Related research → next detail (score passed via `extra`).
2. **AI loop:** any semantic entry (`ResultCard`, `RecRail`, dashboard recs) passes `similarity: double` through route `extra`. Detail shows `ScoreMeter` only when non-null. Direct loads / keyword taps pass nothing — meter stays off.
3. **Submit / Curate (faculty):** `/faculty/thesis/new` → PDF attach → submit as `draft` → admin reviews in `/admin/thesis/management` → status dropdown → published.
4. **Admin governance:** `/admin/dashboard` (KPIs + analytics + activity) → management table (approve/publish/archive, edit, delete) → users (activate/deactivate, role change) → programs (taxonomy).
5. **Student library:** dashboard `Your Saved` count → `/saved` (tabs + unsave) → `/profile` (identity + top-3 preview + View All Saved).

Shared transitions: every route fades + rises (single shared `CScholarTransitionBuilder`, no per-route code). Thesis banner + title are `Hero` flights (`thesisBannerTag(id)`, `thesisTitleTag(id)`); detail is the target — list cards set `heroBanner: false` when rendering the target route. Avatar hero (`userAvatarHeroTag`) flies shell → profile; profile route disables shell source.

## 4. State (Riverpod providers) — what feeds each page

| Provider | Source endpoint | Used by |
|----------|-----------------|---------|
| `authProvider` / `currentUserProvider` / `currentUserRoleProvider` | `POST /api/auth/login`, `POST /api/auth/register`, `GET /api/auth/me` | router guards, all shells, profile/settings |
| `thesisListProvider(ThesisListParams)` | `GET /api/theses?q&programId&academicYearId&categoryId&keyword&sortBy&researchType&showAll` | repository, admin dashboard analytics, admin management |
| `semanticSearchProvider(query)` | `POST /api/embeddings/search` | repository semantic branch, `RecRail` |
| `thesisProvider(id)` / `thesisDetailProvider` | `GET /api/theses/{id}` | detail screen, admin/faculty edit prefill |
| `recommendedThesesProvider(id)` | `GET /api/theses/{id}/recommend` | detail Related research |
| `recommendationsProvider` / `recommendationAnchorProvider` | `POST /api/recommendations` (one anchor id: last viewed/saved study) | dashboard Recommended for You |
| `recentThesesProvider` | latest theses | dashboard Recent Studies |
| `savedThesisIdsProvider` / `savedThesesProvider` | device-local saved ids (SharedPreferences) + thesis lookup | dashboard count, saved screen, profile preview, detail save toggle, result-card bookmark |
| `programsProvider` / `academicYearsProvider` / `categoriesProvider` / `keywordsProvider` / `authorsProvider` / `advisersProvider` / `researchTypesProvider` | `GET /api/programs`, `/api/academic-years`, `/api/categories`, `/api/keywords`, `/api/authors`, `/api/advisers`, `/api/research-types` | repository filters, all thesis forms, admin programs screen |
| `dashboardStatsProvider` | `GET /api/dashboard/stats` (admin) | admin dashboard KPIs |
| `publicStatsProvider` | `GET /api/stats/summary` | student dashboard metrics |
| `recentActivityProvider` / `facultyActivityProvider` | `GET /api/dashboard/recent-activity`, `GET /api/faculty/activity` | admin / faculty dashboards |
| `facultyStatsProvider` / `facultyThesesProvider` / `facultyAdviseesProvider` / `facultyAnalyticsProvider` | `GET /api/faculty/dashboard`, `/api/faculty/theses`, `/api/faculty/advisees`, `/api/faculty/analytics` | all faculty screens |
| `usersProvider` | `GET /api/users` (admin) | admin user management |
| UI-local: `searchQueryProvider`, `searchFiltersProvider`, `adminThesisSearchProvider`, `viewedThesisIdProvider` | in-memory only | repository / admin search boxes, filters |

Mutations: `thesisApi.create/update/delete/updateStatus`, `uploadApi.uploadPdf`, `apiService.post/put` for taxonomy + users. Every mutation invalidates + refreshes its list provider before confirming (filter-preserving refresh).

## 5. Backend API (FastAPI) — endpoints the frontend actually calls

- **Auth:** `POST /api/auth/register` (201), `POST /api/auth/login`, `GET /api/auth/me` (login required)
- **Users (admin):** `GET /api/users`, `POST /api/users` (201), `PUT /api/users/{id}`, `PUT /api/users/{id}/active`
- **Theses:** `GET /api/theses` (filters above), `GET /api/theses/{id}`, `POST /api/theses` (201, login; faculty forced `draft`), `PUT /api/theses/{id}`, `DELETE /api/theses/{id}`, `GET /api/theses/{id}/pdf` (token via `?token=` for browser open)
- **Search/AI:** `POST /api/embeddings/search` (login), `GET /api/theses/{id}/recommend`, `POST /api/embeddings/generate/{thesis_id}` + `generate-bulk` + `bulk-status` (admin)
- **Dashboards:** `GET /api/dashboard/stats` + `/api/dashboard/recent-activity` (admin/login), `GET /api/stats/summary` (public), `GET /api/faculty/dashboard` + `/api/faculty/activity` + `/api/faculty/theses` + `/api/faculty/advisees` + `/api/faculty/analytics` (login)
- **Metadata:** `GET /api/programs|/api/academic-years|/api/categories|/api/keywords|/api/authors|/api/advisers|/api/research-types`; taxonomy CRUD `POST|PUT|DELETE /api/authors|/api/advisers|/api/categories|/api/programs|/api/academic-years` (admin)
- **Upload/OCR:** `POST /api/upload/pdf` (login), `POST /api/ocr/pdf` (admin)
- **Ops:** `GET /health`, `GET /api/health`, `GET /api/db-test`, custom `/docs` + `/swagger.json`

PDF flow: pick → `uploadApi.uploadPdf(bytes, name, thesisId?)` → `pdfUrl` stored on form → served at `/api/theses/{id}/pdf`. OCR (`PyMuPDF`) + chunk + embed (`all-MiniLM-L6-v2`) happen server-side; bulk embed is async with status polling.

## 6. Database (`db/schema.sql`, schema `ceit_repo`, 18 physical tables = 16 domain + 2 operational)

`users` (role CHECK student/faculty/admin) → `programs`, `academic_years`, `theses` (status lifecycle `draft→approved→published→archived`) → `authors` + `thesis_authors`, `advisers` + `thesis_advisers`, `categories` + `thesis_categories`, `keywords` + `thesis_keywords`, `thesis_files` (PDF), `thesis_embeddings` (pgvector 384-d), `search_logs`, `recommendation_logs`. Operational: `thesis_reviews` (lifecycle audit trail) and `import_jobs` (bulk-import job state). Details: `docs/ERD.md`, `docs/data_dictionary.md`, `docs/normalization.md`, `docs/requirements_traceability.md`.

## 7. Thesis lifecycle & invariants for any rebuild

- Status is a server-owned string: `draft` → `approved` → `published` → `archived`. Faculty creates always land `draft`; only admins publish.
- A missing score means no meter: never fabricate similarity. `extra == null` → no `ScoreMeter`, no badge.
- Recommendations are live semantic matches for the current query/thesis — never fake, never interest-tracked.
- Every async slot keeps layout height across loading → data → error (skeleton matches content box; refresh keeps rows, no skeleton flash).
- `DataTable` rows are not widgets: tables enter with their card, never row-staggered.
- Page scroll views carry a 20px horizontal gutter inside the viewport. Shell padding sits outside the scrollable, so only the inner gutter keeps card shadows and the scrollbar off the content edge.
- One entrance language everywhere: fade + rise from below, no side/top slides. (Motion tokens, not style — keep the rule, pick your own duration.)
- Text scale to 200% + 400px phones must not overflow: header actions shrink (`Flexible`), filter clusters wrap, tables scroll horizontally.

## 8. Design Tokens (Soft UI v4 — mobile is the source of truth)

The web and mobile now share **one** surface system. `frontend/lib/core/material/cscholar_mobile_tokens.dart` is the single source of truth; `CScholarColors` and `CScholarMaterial` alias it, so the two can never drift. Gold and glass are retired — coral carries attention/AI, panels are flat with soft green-tinted shadows. **Web and mobile both run light and dark**, from one switch and one palette (`frontend/lib/core/material/cscholar_palette.dart`).

### Color

| Token | Hex | Role |
|-------|-----|------|
| `paper` | `#F8F6F0` | Page canvas (warm paper) |
| `surface` | `#FFFEFA` | Cards, panels, floating sidebar |
| `surfaceSoft` | `#F1F3ED` | Input wells, tracks, skeleton bases |
| `cream` | `#F4EFE6` | Alternate warm wash |
| `mint` | `#DCEEE5` | Active pill, published chip, success tint |
| `green` | `#174F3D` | Primary actions, fills, active ink (white text 9.45:1) |
| `green2` | `#2D7159` | Hover, eyebrow text, secondary accent (5.38:1 on paper) |
| `greenDeep` | `#0F3B2E` | Pressed fill, green shadow tint |
| `ink` | `#17231E` | Headings and body (15.0:1 on paper) |
| `muted` | `#748079` | Placeholders / decorative only (3.81:1) |
| `mutedInk` | `#5A665F` | Secondary text (5.55:1 on paper) |
| `line` | `403E32 @ 9%` | Hairline borders, dividers, topbar edge |
| `coral` / `coralSoft` | `#F17B5B` / `#FFE3DA` | AI / attention accent and tint |
| `coralInk` | `#A63E25` | Coral text, draft status, errors (5.17:1 on coral soft) |
| `lilac` / `lilacSoft` | `#7369AD` / `#E8E4F5` | Faculty accent and tint |
| `lilacInk` | `#5B5194` | Faculty text, approved status (5.53:1 on lilac soft) |

Semantic: `info` = `green2`, `infoLight` = `mint`, `warningFg` / `error` = `coralInk`, `errorLight` = `coralSoft`, `success` = `green`. Role accents: student `green2`, faculty `lilacInk`, admin `coralInk`. Status fills: published `green`, approved `green2`, draft `coralInk`, archived `mutedInk`.

Raw accents are **fills**. Body copy and small labels use the text-safe inks (`mutedInk`, `coralInk`, `lilacInk`), which clear 4.5:1 on paper and on their own tints.

### Light / dark

One mode for the whole app, web and mobile, in `core/material/cscholar_palette.dart`.

- **One switch, top-right.** Every desktop topbar carries `ThemeModeButton` in its top-right cluster, immediately LEFT of the identity pill — the same order as the mobile header; the auth screens float the same control in the corner.
- **Persisted** under `cscholar-theme-dark` (`SharedPreferences`), falling back to the retired mobile-only key. Read once in `main()` before `runApp`, so start-up never flashes the wrong mode.
- **Tokens, not branches.** `CScholarColors` / `CScholarMaterial` are getters over `CScholarPalette.active`; screens keep naming tokens and never ask about the mode. Note that these are values read at paint time — never cache one in a `const` or a long-lived field.
- **Ink and fill are split.** Light reuses one green for both; dark cannot. `primaryGreen` / `gelTop` are text-safe inks (light mint at night), `primaryFill` / `actionFill` are the solids that carry white labels (deep green at night). A white glyph always rides a fill token.
- **Dark palette** (`paperDark #17201C`, `surfaceDark #202A25`, `well #26312B`, ink `#EDF5EF`, accent `#80C4A6`, action `#2E7D63`, danger ink `#FF8F7A`): body copy ≥ 14:1, secondary and accent inks ≥ 7:1, white on the action fill ≥ 5:1. Pinned by `test/theme_mode_test.dart`.
- **Mode-stable art.** Cover gradients and `bannerPalette` never flip — white glyphs sit on them in both modes.
- **Iris wipe** (`CScholarMotion.themeSwap`, 720 ms). The frame on screen is captured, the palette flips, and the captured (old-theme) frame stays on top with an expanding circular hole cut out of it — centred on the switch itself, because the button reports its icon centre. The circle ends once it has passed the farthest corner, then the frozen frame is dropped. Only the clip changes per frame, and the app sits in its own repaint boundary, so a wipe never re-rasterizes the page. If the platform cannot rasterize the frame, or the capture misses `CScholarMotion.themeCapture` (90 ms), the palette flips under a covering disc that dissolves instead. Reduced motion swaps instantly.
- **Route rebuild.** The Navigator caches the page it was handed, so a root rebuild never repaints a route. Every route body in `app_router.dart` is wrapped in `CScholarPaletteRebuild`, which subscribes to `CScholarPaletteScope` and rebuilds the page exactly when the painted mode flips.

### Typography

| Surface | Heading / values | Body / labels / metadata |
|---------|------------------|--------------------------|
| Web + mobile | **Manrope** (`CScholarTextStyles.heading`) | **DM Sans** (`CScholarTextStyles.body`) |

Poppins and Inter are gone from the UI. `poppins()` / `inter()` remain as deprecated aliases that render Manrope / DM Sans so old call sites compile; new code uses `heading` / `body`.

### Geometry

| Token | Value | Use |
|-------|-------|-----|
| card | `23` | `ClaySurface` / `CScholarCard` |
| CTA | `22` | primary / secondary pill buttons |
| well | `18` | text fields, selects, search wells |
| nav pill | `17` | sidebar active pill |
| sheet | `26` | dialogs, bottom sheets |
| tag | `8` | small type/chip tags |
| pill | `999` | capsule chips and avatars |

### Elevation

Two diffuse layers, tinted green-black (never pure black):
`0 12px 28px rgba(35,56,45,0.075)` + `0 2px 6px rgba(35,56,45,0.035)`.
Floating chrome / dialogs use the deeper `overlay` recipe (`0 22px 54px`). High contrast drops all shadows and keeps the strong rim.

### Motion

One language everywhere: fade + rise on `Cubic(0.16, 1, 0.3, 1)` (300–500 ms), `scale(0.96)` press feedback, `-3px` hover lift, and gated ambient loops (orbit, wash, shimmer, pulse). No side/top slides.

