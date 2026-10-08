# CScholar — Motion & Micro-Interaction Upgrade Brief

> **What this document is:** a ready-to-paste prompt for an AI coding agent (Kilo / Cline / Claude Code)
> working inside the CScholar repo. Paste **PART 0 → PART 13** as a single task, then let the agent
> work phase by phase (PART 11).
>
> **Resuming an interrupted run?** Read **PART R** first — it records which phases are already
> committed, the verified test baseline, the measured gap list, and whether anything is left to do.
>
> **What this document is not:** a request to redesign, restyle, or relayout CScholar. The material
> system (clay + glass, sage canvas, WCAG audits) is already good and is **frozen**. This brief adds
> *time* — motion, choreography, micro-interactions — on top of it.
>
> Design language source: the sibling project `csucc_wayfinder/mobile_app` (CSUCC WayFinder),
> analysed in PART 1.

---

## PART R — PROGRESS & RESUME STATE (read this first)

> **Status: THE RUN IS COMPLETE.** All eight phases (1–8) are committed and verified;
> HEAD = `6073cc9` (Phase 8). There is nothing left to resume — **R.7** is the post-run
> verification, **R.6** shows every measured gap closed.
>
> **Re-verified on this tree (2026-10-05, at `6073cc9`):** `flutter analyze` → *No issues found*;
> `flutter test` → **290 passed**; `flutter build web --release` ships; `frontend/pubspec.yaml`
> untouched since the baseline (no new dependency). Working tree clean except this document
> (its own edit, uncommitted) and untracked `.idea/`.

### R.1 Commit map

| Phase | Commit | Subject | State |
|---|---|---|---|
| — | `a651773` | Previous session's uncommitted work (pre-upgrade baseline; this doc landed here) | baseline |
| 1 · Foundation | `905f72f` | Add the motion budget v2, named pitches and the ambient gate | ✅ done |
| 2 · Primitives | `57f7c29` | Add the ten motion primitives and demo them in the design lab | ✅ done |
| 3 · Chrome & navigation | `19b7897` | Seat the topbar, morph the nav glyphs, layer the route transition, unify dialog/sheet openings | ✅ done |
| 4 · Controls | `df6af1a` | Spring the controls: overshoot releases, swapping labels, turning glyphs | ✅ done |
| 5 · Dashboards | `73fc4bb` | Choreograph every page: named pitches, diagonal KPIs, living numbers | ✅ done |
| 6 · Repository & results | `3b81dbc` | Seat the results: silhouettes, re-forms, seated strip, living cards | ✅ done |
| 7 · Thesis detail & save | `65ed7b2` | Fly the thesis: banner/title heroes, metered matches, tactile saves | ✅ done |
| 8 · Polish & proof | `6073cc9` | Polish the edges: floating empties, morphing glyphs, proven release | ✅ done — **HEAD** |

### R.2 Phase 1 delivered (`905f72f`)

`core/constants/cscholar_constants.dart` + `common/motion.dart`:

- **`CScholarMotion`** — the two-budget token class. Transition: `micro` 120 / `swap` 200 /
  `enter` 280 / `page` 360. Ambient: `breathe` 2400 / `drift` 16000 / `shimmer` 1400 / `pulse` 1200.
  Plus the `ambientEnabled` global kill switch.
- **`MotionPitch`** enum, four presets: `tight` (24/160/8), `page` (48/240/12), `feature`
  (72/320/16), `result` (56/280/14).
- **`CScholarCurves`** extended with `settle`, `overshoot`, `exit`, `anticipate`, `steady`.
  **`standard` and `entrance` are unchanged.**
- `EntranceReveal` gained `scaleFrom`; `Stagger` / `StaggerColumn` gained `pitch:` and
  `origin:` / `columns:` — all **optional**, so no existing call site changed behaviour.
- `CScholarDurations` was **not** touched (`motion_test.dart` pins `slow == 300ms`).

### R.3 Phase 2 delivered (`57f7c29`)

New file `common/motion_ambient.dart` (353 lines), additions to `common/motion.dart` (now 1100
lines) and `common/loading_skeleton.dart`:

- **One-shot:** `AnimatedSwap` (+ `SwapStyle`), `MorphIcon`, `TactileToggle`, `ScoreMeter`,
  `ScrollVeil`.
- **Ambient** (in `motion_ambient.dart`): `PulseDot`, `BreathingGlow`, `DriftingWash`.
- **Skeleton:** `ThesisSkeleton`.
- Every ambient widget carries its **own** `RepaintBoundary` and returns a static equivalent when
  `ambientMotionEnabled` is false — so a caller cannot break the gate or the boundary by forgetting.
- Design lab gained **section 15 · Motion vocabulary** (~line 1291) and **section 16 ·
  Choreography** (~line 1590).
- `test/motion_test.dart` grew from 10 to **23 cases**; `screens_render_test.dart` installs the
  ambient kill switch in `setUpAll`.

### R.4 Phase 3 delivered (`19b7897`)

- `clay_nav_list.dart` — the selected glyph now goes through `MorphIcon`; the focus ring fades in.
- `topbar.dart`, `app_shell.dart`, `student_layout.dart`, `faculty_dashboard_screen.dart` —
  `ScrollVeil` seats the chrome on scroll.
- `motion.dart` — `cscholarTransition` now drives the **outgoing** half through
  `secondaryAnimation` (the covered page's retreat), plus the `showClayDialog` helper.
- `showClayDialog` adopted in `admin_programs`, `admin_thesis_management`, `admin_user_management`,
  `login`, `faculty_students`, `faculty_theses`, `faculty_thesis_form`.
- `glass_panel.dart` wired for the new opening; `test/motion_test.dart` +16 lines.

### R.5 Phases 4–8 delivered (`df6af1a`, `73fc4bb`, `3b81dbc`, `65ed7b2`, `6073cc9`)

- **Phase 4 · Controls** (`df6af1a`, 2026-10-03) — button releases spring on `overshoot` while the
  label ↔ "Saving…" swap runs in a build-time measured slot (the button never resizes under the
  pointer); icon-button glyphs turn 90° via `AnimatedRotation`; fields fade the focus ring as an
  opacity ramp of a fixed hue, lift the placeholder 2px by transform, and swap error text through
  `AnimatedSwap`; the select caret turns 180° while the menu is up (open state derived from
  `ModalRoute.isCurrent`, so barrier-dismiss and Escape reset it); `ClayChip` sinks 0.96 and pops
  its check into a permanently reserved slot, so toggling never reflows the `Wrap`.
- **Phase 5 · Dashboards** (`73fc4bb`, 2026-10-03) — all 19 `StaggerColumn` call sites carry a named
  `MotionPitch`; KPI strips cascade diagonally via the new `StaggerColumn.diagonalDelay`; explicit
  PART 7 beats on every dashboard; `KpiCard` counts in tabular figures with a one-shot,
  change-only sweep; `DriftingWash` sits behind the student greeting hero.
- **Phase 6 · Repository & results** (`3b81dbc`, 2026-10-05) — the repository loads into
  `ThesisSkeleton` (same box the cards land in, bottom spacing matched); result columns are keyed
  on the query/filter/sort/mode signature so every re-form replays the cascade with a 0.98 settle
  (`Stagger.scaleFrom`, default 1.0 elsewhere); the results header seats past the shell
  `ScrollVeil` trigger; `ThesisCard` grows a static corner glow and a cropped 1.03 banner zoom on
  web hover; rail rows step on `MotionPitch.tight`.
- **Phase 7 · Thesis detail & save** (`65ed7b2`, 2026-10-05) — `ThesisCard` hosts the banner + title
  `Hero` sources (slab-only shuttle; `heroBanner: false` on the detail route mirrors
  `heroAvatar`); detail renders the banner target statically, flies the title, meters the match
  with `ScoreMeter` (score handed through the route extra, absent on direct loads), and saves
  through `TactileToggle`; the saved list removes via the toggle and re-forms on an ids-keyed
  cascade.
- **Phase 8 · Polish & proof** (`6073cc9`, 2026-10-05) — `EmptyState` settles (`scaleFrom: 0.96`) and
  its tile floats ±2px on `breathe` behind a private gated loop (own `RepaintBoundary`, static
  under reduced motion / high contrast / the kill switch); the last hard icon swaps — login + admin
  password visibility, result save, admin block/reactivate — go through `MorphIcon`
  (`NeumorphIconButton` gained optional `selectedIcon`/`selected`, defaults preserve the static
  glyph); SnackBars audited, no change needed (Material's entrance already fades + rises);
  `main.dart` switch/checkbox themes stay colour-only by design — `NeumorphToggle` is the tier-3
  answer.

### R.6 Evidence-based gap list (measured; ALL CLOSED)

Measured by grep on the current tree — these are facts, not estimates:

| PART 12 item | Measured on this tree (2026-10-05) | State |
|---|---|---|
| `MotionPitch` used **by screens** | `pitch: MotionPitch` appears **22 times across 19 screens**; line-checked: **0** `StaggerColumn(` call sites lack a pitch | ✅ closed |
| `TactileToggle` applied | `thesis_card.dart`, `thesis_detail_screen.dart`, `saved_theses_screen.dart` | ✅ closed |
| `ScoreMeter` applied | `thesis_detail_screen.dart` | ✅ closed |
| `ThesisSkeleton` applied | `repository_screen.dart` | ✅ closed |
| `DriftingWash` applied | `student_dashboard_screen.dart` (greeting hero) | ✅ closed |
| `PulseDot` / `BreathingGlow` applied | design-lab demo only — **no PART 12 line requires them**, and PART 13 forbids motion that answers neither question; apply them the day a screen earns a live indicator or a breathing halo | ⚠️ vocab only, by choice |
| Thesis `Hero` continuity | `thesisBannerTag` / `thesisTitleTag` used in `thesis_card.dart` + `thesis_detail_screen.dart` | ✅ closed |
| Controls micro-interactions | `neumorph_controls` / `neumorph_field` / `neumorph_select` / `clay_objects` all landed in Phase 4; the last hard glyph swaps in Phase 8 | ✅ closed |

So: the vocabulary is **applied**. Every box in PART 12 is satisfied — R.7 holds the verification
commands, and the PART 11 table below is fully committed.

### R.7 Final state & verification (nothing left to resume)

> All eight phases are committed. If you are an agent asked to "continue" this brief: **the work is
> done — verify, do not re-do.**
>
> 1. `cd frontend` and run `flutter analyze` → expect *No issues found*; `flutter test` → expect
>    **290 passed** (re-verified 2026-10-05 at `6073cc9`).
> 2. Belt-and-braces: `flutter build web --release` → expect `✔ Built build\web` (proven twice on
>    2026-10-05; ignore the wasm dry-run notice printed to stderr — exit code stays 0).
> 3. If both are green, report the run complete and stop. Do not re-litigate the vocabulary, do not
>    "improve" an already-committed phase, do not weaken `motion_test.dart`, and do not touch
>    `CScholarDurations`.
>
> Residuals deliberately left — they are not defects: `PulseDot` and `BreathingGlow` remain
> vocabulary + design-lab demos (no screen currently earns a live indicator or a breathing halo
> under PART 13's "answer a question" law); SnackBars, the `main.dart` switch/checkbox themes and
> `CScholarDurations` were audited and left unchanged by design (see Phase 8 in R.5).
>
> Any future motion work starts from the committed vocabulary — `CScholarMotion`, `MotionPitch`,
> `common/motion.dart`, `common/motion_ambient.dart` — and keeps every PART 13 rule: one commit per
> change, `flutter analyze` clean and `flutter test` green at the end, and a stop-and-report if the
> brief conflicts with the code.

---

## PART 0 — Context you must not break

### 0.1 The repo you are editing

```
CScholar/
├── backend/     Flask API (do not touch for this task)
├── db/          PostgreSQL schema (do not touch)
├── docs/        ← this file lives here
└── frontend/    Flutter web + mobile  ← EVERYTHING IN THIS BRIEF LIVES HERE
    ├── lib/
    │   ├── core/
    │   │   ├── constants/cscholar_constants.dart   ← CScholarColors, CScholarTextStyles,
    │   │   │                                          CScholarRadius, CScholarSpacing,
    │   │   │                                          CScholarDurations, CScholarCurves,
    │   │   │                                          CScholarShadows, CScholarSimilarity
    │   │   ├── material/material_tokens.dart       ← CScholarMaterial (THE MATERIAL LAW)
    │   │   └── router/app_router.dart              ← go_router, kEnableDesignLab
    │   ├── presentation/
    │   │   ├── screens/          (auth, student, repository, thesis, admin/*, faculty/*)
    │   │   └── widgets/
    │   │       ├── common/       motion.dart, hover_lift.dart, cscholar_card.dart,
    │   │       │                 kpi_card.dart, loading_skeleton.dart, clay_nav_list.dart,
    │   │       │                 empty_state.dart, page_header.dart, topbar.dart,
    │   │       │                 app_shell.dart, auth_shell.dart, status_chips.dart
    │   │       └── material/     clay_surface.dart, clay_objects.dart, clay_progress.dart,
    │   │                         glass_panel.dart, neumorph_controls.dart,
    │   │                         neumorph_field.dart, neumorph_select.dart
    │   └── ...
    └── test/
        ├── motion_test.dart          ← pins the motion budget. NEEDS A DELIBERATE UPDATE.
        ├── material_system_test.dart
        ├── screens_render_test.dart  ← every screen × 2 sizes × high-contrast × 200% text
        ├── tier1_surface_test.dart, tier2_surface_test.dart, tier3_controls_test.dart
        └── widget_test.dart, neumorph_select_test.dart
```

Stack: Flutter (SDK `^3.13.1`), Riverpod 3 + `hooks_riverpod`, `go_router` 18, `google_fonts`
(Poppins headings / Inter body), `shimmer`, `freezed`, `file_picker`. **No animation package is
installed and none may be added** — everything here is hand-rolled on `AnimationController` and
implicit animated widgets, matching how `motion.dart` and `clay_nav_list.dart` are already written.

### 0.2 The six invariants (violating any of these = failed task)

1. **THE FUSION LAW** (`material_tokens.dart`): canvas + content panels → **clay**; anything
   pressable → **clay + gel press**; identity objects (avatars, tiles, covers, badges) → **clay +
   gel**; floating chrome/overlay (topbar, rail, search, dialogs, sheets) → **glass**. One style per
   structural role. **Motion must never invent a new material, fill, or rim.**
2. **Contrast is a ratchet.** Every colour touched must keep its measured ratio in
   `CScholarMaterial.ratios`. Gold is decoration only (1.26:1 on clay) — never behind text, never on
   more than 2–3 elements per screen, dropped entirely under high contrast. White on gold is
   1.38:1 — **never**.
3. **Reduced motion is inert, not fast.** Every helper must return the child untouched (no
   `Opacity`, no `AnimationController`, no ticker, no timer) when
   `MediaQuery.disableAnimationsOf(context)` is true. `motionEnabled` / `motionDuration` /
   `motionScale` in `motion.dart` are the existing gates — follow them.
4. **High contrast degrades.** When `MediaQuery.highContrastOf(context)` is true: no blur, no
   gradients, no tinted shadows, no coloured glows, no ambient loops — solid fill + `rimStrong`.
   `ClaySurface` and `GlassPanel` already do this; new motion must obey it.
5. **Transform / opacity / colour / shadow only.** Never animate the layout of a large subtree. No
   `AnimatedSize` on list items, no animated item heights inside a `ListView`, no animated `Padding`
   on a scrolling column. A nav pill may glide; a table row may not reflow.
6. **Web + mobile, one codebase.** No `dart:io`, no platform channels. Haptics are optional and must
   sit behind a capability check that no-ops on web (PART 5.11).

### 0.3 Keep this comment style

The codebase comments *why*, not *what*, and names the failure the code prevents — see the header of
`motion.dart`, the doc comment on `ClaySurface`, and the essay at the top of `clay_nav_list.dart`.
Match that register. A helper with no doc comment explaining the regression it prevents will be
rejected.

### 0.4 Your working agreement

- **One phase per commit.** PART 11 lists the order. Do not start a phase before the previous one
  builds, analyses clean (`flutter analyze`), and passes `flutter test`.
- **Never delete an existing helper.** `EntranceReveal`, `Stagger`, `StaggerColumn`,
  `PressableSurface`, `AsyncCrossFade`, `asyncSlot`, `CountUpText`, `HoverLift`,
  `cscholarTransition`, `userAvatarHeroTag` all stay, with their public signatures intact, because
  screens and tests depend on them. You may *extend* them (new optional params) and you may
  *re-implement* their internals. If you supersede one, keep it as a thin forwarding wrapper and
  document the supersession in its doc comment.
- **Add, then migrate.** Put new primitives in `motion.dart` (or a new sibling
  `motion_ambient.dart` if `motion.dart` passes ~700 lines) and demo them in `design_lab_screen.dart`
  **before** touching any screen. The design lab already renders every material, every component
  state and every a11y fallback; new motion must be reviewable there first.
- If a requirement in this brief conflicts with what you find in the code, **stop and report the
  conflict** rather than silently picking one.

---

## PART 1 — Design style analysis of the reference app (CSUCC WayFinder)

This is the app whose design language you are translating into motion. Analysed from
`csucc_wayfinder/mobile_app/lib`.

### 1.1 Visual identity

| Dimension | WayFinder | What to take from it |
|---|---|---|
| Base | Material 3, `ColorScheme.fromSeed`, Poppins everywhere | CScholar is also M3 + Poppins/Inter. Same family. |
| Palette | CSU deep green `#002C13` / `#014421`, CSU gold `#FDCC3A`, charcoal `#232526`, `#F8F9FB` surfaces | Take the **role assignment** (one dark brand colour for primary surfaces; one gold for time-critical / prestige accents only). **Do not copy the hexes.** |
| Surfaces | 6 tonal container steps + white cards on a grey canvas | CScholar expresses the same ladder with `clayHigh / clay / clayDeep` + a hue-matched tinted shadow. Already equivalent — leave it. |
| Radii | 12 / 16 / 20, pills at 999 | CScholar `CScholarRadius` (6/8/12/16/24/full). Already equivalent. |
| Shadow | Soft, diffused, green-tinted (`#0D002C13`), 18–22px blur, 6–8px Y, negative spread | CScholar `clayDrop()` — same idea, better executed. Leave it. |
| Type | Poppins 700 for critical data, 600 section headers, 400 body, 500 labels; opened `letterSpacing` in the dense timetable | CScholar already has `CScholarTextStyles.pageTitle / cardTitle / sectionLabel`. Reuse; never redefine. |
| Texture | Radial-gradient blob bleeding off card corners (`NextClassCard`), hero gradients, glass bottom nav at 92% white + 16px blur | The *warmth* layer CScholar under-uses. See PART 4.6 and PART 6.3. |

### 1.2 The motion system — the actual thing worth stealing

WayFinder's motion is not decorative; it is a **tokenised vocabulary applied with total
consistency**. Its primitives, with call-site counts, show how load-bearing they are:

| Primitive | What it does | Call sites |
|---|---|---|
| `AppMotion` | duration + curve tokens (`extraShort` 120 / `short` 200 / `medium` 320 / `long` 480ms; `emphasized` `Cubic(0.2,0,0,1)`, `emphasizedDecel`, `entrance`) | 17 |
| `FadeSlideIn(delay:)` | fade + translate-Y entrance with a **stagger delay** | 20 |
| `ScaleIn(delay:)` | fade + 0.92 → 1.0 scale entrance | 9 |
| `TapScale(pressedScale: 0.97, haptic: true)` | springy press-down scale + `HapticFeedback.selectionClick()` | 9 |
| `ShimmerBox` | 1400ms shimmer sweep — a *moving* `LinearGradient` animated by sliding `begin`/`end` alignments | 8 |
| `PulsingDot` | 1200ms `repeat(reverse: true)`, scale 0.85↔1.15 + opacity 1↔0.6, for LIVE / ONGOING | 9 |
| `CountUp` | 900ms `TweenAnimationBuilder` 0 → value for stat tiles | 4 |
| `SoftBlobBackground` | three radial-gradient circles drifting on a **16-second** loop, inside a `RepaintBoundary` for repaint isolation | 5 |
| `Glass` | `ClipRRect` + `BackdropFilter` blur panel | 1 |
| `FadeThroughPageTransitionsBuilder` | theme-wide: the incoming page fades in **and settles from scale 0.94**; the outgoing page fades out | every route |

### 1.3 The seven motion patterns that give WayFinder its "smooth app" feel

1. **Choreographed entrance, not a single fade.** `home_screen.dart` does not fade the page once —
   it assigns explicit delays to explicit blocks: greeting 60ms → ongoing banner 100ms → stats row
   120ms → section label 140ms → conflict banner 180ms → **class list `380 + index * 70`ms** →
   next-class section 440ms. The eye is walked down the page. This is the single largest contributor
   to the perceived quality.
2. **Sliding indicators instead of on/off highlights.** The bottom nav paints one gel pill in an
   `AnimatedPositioned` (`AppMotion.medium`, `AppMotion.emphasized`) that *travels* between tabs. The
   selected icon cross-fades through `AnimatedSwitcher` with an **overshoot** curve
   `Cubic(0.34, 1.56, 0.64, 1.0)`, and the label weight/colour morphs via
   `AnimatedDefaultTextStyle(200ms)`. Three micro-animations on one tap, all transform/colour.
3. **Living numbers.** A `Ticker`-driven countdown (deliberately **not** a `Timer`, so no pending
   timers are left behind and it pauses with the frame clock) ticking once per second, with
   `AnimatedSwitcher(320ms)` + `ClipRect` sliding the old digits up and out, and
   `FontFeature.tabularFigures()` so glyph widths never jitter.
4. **Tactile press on everything.** `TapScale` on cards, icon buttons, document rows, links — press
   sinks 3%, release springs back, and a selection haptic fires on tap-down.
5. **Perceived-performance loading.** Layout-matching `ShimmerBox` skeletons plus an async
   cross-fade, so content *lands* rather than *appears*.
6. **Ambient depth.** Drifting gradient blobs behind hero and empty areas (16s loop) and a pulsing
   dot on anything live. The screen is never dead even when no data changed.
7. **State-change continuity.** `AnimatedContainer` for borders/shadows that change with state
   (conflict red vs. ongoing green on `ClassCard`), `AnimatedSwitcher` for chips that appear and
   disappear, and `Hero(tag: 'class-$code-$day')` carrying the dark time panel from the list card
   into the detail screen.

### 1.4 What WayFinder does that CScholar must **not** copy

- WayFinder has **no accessibility story**: it ignores reduced motion, ignores high contrast, uses
  black-alpha shadows, and leaves `PulsingDot` / `SoftBlobBackground` repeating forever with no gate.
  Its `pumpAndSettle()` would hang. CScholar's suite deliberately uses a frame budget instead (see
  `screens_render_test.dart` line 78) — **keep that discipline and make it explicit** (PART 4.5).
- WayFinder duplicates shadow recipes inline in screens. CScholar's law is that decoration comes from
  `CScholarMaterial` only. Never paste a `BoxShadow` into a screen.
- WayFinder uses only 4 durations and 4 curves. CScholar's upgrade needs a richer set (PART 4), but
  the *sameness* — one curve per intent, reused everywhere — is what to preserve.

---

## PART 2 — CScholar's motion audit: what exists, and what is missing

Measured by grepping `frontend/lib` — these numbers are the baseline your work must move.

### 2.1 What already exists (and is good)

| Primitive | File | Adoption |
|---|---|---|
| `motionEnabled` / `motionDuration` / `motionScale` (reduced-motion gates) | `common/motion.dart` | 22 + 8 refs — well adopted |
| `EntranceReveal` | `common/motion.dart` | 12 refs (shell, page header, empty state, auth shell) |
| `Stagger` / `StaggerColumn` | `common/motion.dart` | used by **every** screen — `StaggerColumn` appears in 20 files |
| `PressableSurface` (press sink) | `common/motion.dart` | only `clay_nav_list.dart`, `rec_rail.dart` |
| `AsyncCrossFade` / `asyncSlot` | `common/motion.dart` | 8 refs |
| `CountUpText` | `common/motion.dart` | 7 refs (`kpi_card.dart` + dashboards) |
| `HoverLift` (web hover lift) | `common/hover_lift.dart` | 9 refs (`CScholarCard(lift: true)`) |
| `CScholarTransitionBuilder` (route transition) | `common/motion.dart` | every route, theme-wide |
| Sliding active pill | `common/clay_nav_list.dart` | all 3 sidebars (admin, faculty, student) |
| `Shimmer` skeletons | `common/loading_skeleton.dart` | 3 refs |
| `Hero` continuity | `userAvatarHeroTag` only | 3 sites (shell avatar → profile avatar) |
| `AnimationController` | 6 refs | `motion.dart`, `clay_progress.dart` |
| `RepaintBoundary` | 5 refs | respected around loops |

### 2.2 The seven gaps that make it feel static

1. **Stagger is uniform and unpitched.** Every screen wraps its blocks in `StaggerColumn` with the
   default `step: 40ms, max: 240ms`. A KPI grid, a hero banner and a result list all enter on the
   same rhythm, so the effect reads as "everything fades in together" rather than choreography. There
   is no per-block delay, no directional variety, no diagonal cascade for grids.
2. **Two curves for the whole app.** `CScholarCurves` has exactly `standard = easeOutCubic` and
   `entrance = easeOut`. There is **no spring/overshoot curve anywhere** (WayFinder's
   `Cubic(0.34, 1.56, 0.64, 1.0)`), no mirrored exit curve, no linear for continuous motion.
   Overshoot is what makes a toggle feel physical instead of bureaucratic.
3. **Micro-interactions are missing on interactive controls.** Only 3 `AnimatedSwitcher`, 5
   `AnimatedContainer`, 3 `AnimatedPositioned`, 1 `AnimatedOpacity`, 1 `AnimatedAlign`, 1
   `AnimatedDefaultTextStyle` in the entire app. And: **`AnimatedScale`, `AnimatedSlide` and
   `AnimatedRotation` have 0 uses.** So toggling a save/bookmark, selecting a filter chip,
   submitting a form, rotating the search glyph, or settling a checkbox happens by instant state
   swap.
4. **A hard 300ms ceiling on everything.** `CScholarDurations` is `fast 150 / normal 250 / slow 300`
   and `motion_test.dart` asserts `CScholarDurations.slow == 300ms` and that `EntranceReveal.duration
   <= CScholarDurations.slow`. This deliberately makes state changes snappy, but it also means there
   is **no room for a page-level, hero-level or ambient gesture** — the current escape hatch
   (`ClayLoader`) is the only long-running animation. Nothing breathes, drifts, glows or pulses.
5. **No shared-element continuity except the avatar.** `Hero` exists for `userAvatarHeroTag` only.
   Tapping a thesis card → detail screen has **no continuity at all**: the banner, title and match
   badge all disappear and reappear.
6. **No ambience.** WayFinder has `SoftBlobBackground` (drifting blobs) + `PulsingDot` on 9 elements.
   CScholar has none: no pulse on a live/syncing indicator, no drift behind a hero, no breathing gold
   halo on the AI-prestige marks (`goldGlow` is currently a *static* shadow).
7. **Scroll is not choreographed.** No scroll-linked behaviour: the topbar does not gain/lose glass
   as you scroll, the repository filter bar does not react, no header collapses, no parallax on a
   thesis banner, no scroll-triggered stagger for paginated results.

### 2.3 Non-gaps (do not "fix" these)

`ClaySurface`, `GlassPanel`, `ClayChip`, `ClayIconTile`, `GelAvatar`, `ClayNavList`, the focus rings,
the keyboard path on nav rows, and the high-contrast/reduced-motion fallbacks are already correct and
unusually well reasoned. Extend, do not rewrite.

---

## PART 3 — The brief: the target feel

> **One sentence:** CScholar should feel like a precision instrument that is *alive* — every state
> change is a continuous, physical motion; every page opens with a choreographed cascade; a few
> ambient gestures (a breathing halo, a pulsing sync dot, a drifting hero wash) make the surface read
> as living; and every one of those gestures vanishes instantly for a user who asks for reduced
> motion or high contrast.

Six observable outcomes (each is a phase in PART 11 and a box in PART 12):

1. **Pitched entrances.** Every page has a deliberate delay map (header → hero → metrics → list),
   with grids cascading diagonally and lists stepping by index. Nobody sees a single blanket fade.
2. **Physical controls.** Every pressable thing sinks on press and springs back; every state toggle
   (save, select, expand, submit, filter) overshoots slightly and settles.
3. **Continuous numbers.** Every changing number counts, tweens or slides — never pops — and never
   reflows (tabular figures).
4. **Continuity across routes.** Thesis card → thesis detail carries the banner / cover and title
   via `Hero`; the page underneath fades and scales rather than vanishing.
5. **Ambient life.** Two or three looped gestures per screen, maximum, all gated and all inside a
   `RepaintBoundary`.
6. **Loading that behaves.** Skeletons match the real card silhouette, shimmer, and cross-fade into
   content so nothing jumps.

---

## PART 4 — The motion foundation

Add this **beside** the existing tokens, never replacing them. `CScholarDurations` and the existing
two `CScholarCurves` keep their exact current values — `motion_test.dart` pins them and screens
depend on them. Everything new lands in one new class.

### 4.1 New token class — add to `core/constants/cscholar_constants.dart`

```dart
/// Motion budget v2 — the layer above [CScholarDurations].
///
/// [CScholarDurations] remains the *interaction* budget and keeps its 300ms ceiling
/// (`motion_test.dart` pins `slow == 300ms`): a control that reacts to a tap must answer
/// inside 300ms or it feels laggy. What was missing was anywhere for a *page-level* or
/// *ambient* gesture to live, so every long-running motion in the app ended up crammed
/// into 300ms and nothing could breathe.
///
/// Hence two named budgets, and the rule that decides which one you use:
///
///   * TRANSITION ([micro] .. [page]) — a response to a user action or a route change.
///     Bounded, interruptible, one-shot. Must never exceed [page].
///   * AMBIENT ([breathe], [drift], [shimmer], [pulse]) — a loop that runs while a state
///     holds (idle, live, syncing, loading). Gated by [ambientEnabled], so tests and
///     low-power users never see one.
///
/// Nothing else: if you need a duration that is not here, you are animating the wrong thing.
class CScholarMotion {
  // ------------------------------------------------------------- transition
  /// Press, hover, focus — the twitch a control makes under the pointer.
  static const Duration micro = Duration(milliseconds: 120);

  /// State swap: chip selects, icon morph, error text replaces hint.
  static const Duration swap = Duration(milliseconds: 200);

  /// Entrance for a block: one reveal, or one step of a cascade.
  static const Duration enter = Duration(milliseconds: 280);

  /// Page-level: route transitions, hero flights, the outgoing page's retreat.
  /// This is the ceiling for any one-shot motion in the app.
  static const Duration page = Duration(milliseconds: 360);

  // ---------------------------------------------------------------- ambient
  /// Slow breath: a halo deepening, an icon tile floating ±2px.
  static const Duration breathe = Duration(milliseconds: 2400);

  /// Very slow wash behind a hero panel. Long enough to be noticed only in
  /// peripheral vision — the point is that it is never seen to loop.
  static const Duration drift = Duration(milliseconds: 16000);

  /// Skeleton shimmer sweep. One full pass.
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// Live / syncing indicator pulse.
  static const Duration pulse = Duration(milliseconds: 1200);

  // ------------------------------------------------------------- global gate
  /// Kill switch for ALL looping motion.
  ///
  /// A repeating [AnimationController] makes `pumpAndSettle()` never terminate, and
  /// `screens_render_test.dart` already had to work around this for `ClayLoader` with a
  /// hand-rolled frame budget. That workaround stays, but the gate makes it explicit and
  /// lets a test (or a low-power mode) turn every loop off in one line. Tests must set
  /// `CScholarMotion.ambientEnabled = false` in `setUp` and restore it in `tearDown`.
  static bool ambientEnabled = true;
}

/// True when a LOOPING animation may run.
///
/// Loops are decoration: they add nothing a user must perceive. So they are the first
/// thing dropped — under reduced motion, under high contrast (where gradients and glows
/// are already stripped, so a drifting blob would be a floating void), and whenever the
/// global ambient switch is off.
bool ambientMotionEnabled(BuildContext context) =>
    CScholarMotion.ambientEnabled &&
    motionEnabled(context) &&
    !MediaQuery.highContrastOf(context);
```

### 4.2 Curve set — extend `CScholarCurves`

The app currently has two curves for every job, which is why nothing can express "arrive
confidently", "overshoot slightly" or "leave". Add these; keep the existing two untouched:

```dart
class CScholarCurves {
  static const Curve standard = Curves.easeOutCubic;   // unchanged
  static const Curve entrance = Curves.easeOut;        // unchanged

  /// Material 3 "emphasised": fast out, soft landing. Default for anything that MOVES TO
  /// a new place — sliding pill, drawer, hero flight, page push.
  static const Curve settle = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Springy settle for micro-interactions: a save icon, a checkmark, a badge. The tiny
  /// overshoot is what makes a toggle read as physical. Do NOT use it on anything larger
  /// than ~80px — a big surface that overshoots reads as broken.
  static const Curve overshoot = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Mirrored exit. Leaving must be faster and less fussy than arriving, so entrances use
  /// [settle] while exits use this.
  static const Curve exit = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Ease-in-out for something that LOOPS (breathe, drift, pulse): the two halves must be
  /// symmetric or the loop visibly hitches at the turnaround.
  static const Curve anticipate = Cubic(0.4, 0.0, 0.6, 1.0);

  /// Only for continuous, constant-rate motion (shimmer sweep, spinner).
  static const Curve steady = Curves.linear;
}
```

### 4.3 Choreography presets — the answer to "stagger is uniform"

Named entrance rhythms, plus a grid cascade. This is the change that turns "everything fades in"
into a choreographed page.

```dart
/// Named entrance rhythms. A page's delay map is a design decision, so it is named and
/// shared rather than re-invented with magic numbers per screen.
///
/// [step] is the gap between siblings; [max] clamps the last sibling's delay so a long list
/// can never crawl in; [rise] is how far each block travels.
enum MotionPitch {
  /// Dense lists, table rows, chips. Barely a stagger — it reads as one gesture.
  tight(step: Duration(milliseconds: 24), max: Duration(milliseconds: 160), rise: 8),

  /// The default for page blocks below a header.
  page(step: Duration(milliseconds: 48), max: Duration(milliseconds: 240), rise: 12),

  /// Feature cards and KPI strips: a slower, more deliberate walk.
  feature(step: Duration(milliseconds: 72), max: Duration(milliseconds: 320), rise: 16),

  /// Thesis results, saved studies. Long enough to be seen, clamped hard.
  result(step: Duration(milliseconds: 56), max: Duration(milliseconds: 280), rise: 14);

  const MotionPitch({required this.step, required this.max, required this.rise});
  final Duration step;
  final Duration max;
  final double rise;
}
```

Extend the existing widgets with **optional** params so every current call site keeps its behaviour:

- `StaggerColumn({..., MotionPitch pitch = MotionPitch.page, int columns = 1})` — when `columns > 1`,
  the delay for child `i` becomes `(i % columns) * step + (i ~/ columns) * step * 1.6`, which makes a
  2- or 3-up KPI strip cascade **diagonally** instead of left-to-right-then-wrap.
- `Stagger({..., Offset origin = const Offset(0, 1)})` — the direction each block travels *from*. A
  right-hand rail enters from `Offset(0.06, 0)`; a footer rises from `Offset(0, 0.5)`.
- `EntranceReveal({..., double scaleFrom = 1.0})` — pass `0.97` for cards that should *settle* rather
  than just fade. Default `1.0`, so no existing call site changes behaviour.

Under reduced motion all three must still return the child with **no `Opacity`, no `Transform`, no
controller, no ticker** — `motion_test.dart` asserts `findsNothing` for the `Opacity` inside
`EntranceReveal`.

---

## PART 5 — New motion primitives

Ten primitives, all in `presentation/widgets/common/motion.dart` (move the ambient ones to
`motion_ambient.dart` if `motion.dart` exceeds ~700 lines). Every one must be demoed in
`design_lab_screen.dart` in the states the lab already switches between: normal, reduced motion,
high contrast — plus 200% text.

**One rule for all of them:** if a primitive would need to animate layout to work, it is the wrong
primitive. Everything below is transform / opacity / colour / shadow only.

### 5.1 `AnimatedSwap` — one tuned `AnimatedSwitcher`

The app has only 3 `AnimatedSwitcher`s and two of them hand-roll their `transitionBuilder`. Give the
app one switcher with four named styles, then migrate every ad-hoc one to it.

```dart
/// A tuned children-swapper: fade + ONE secondary motion, chosen by intent.
///
/// A bare [AnimatedSwitcher] cross-fades, which on a green-on-green clay panel reads as a
/// flicker rather than a change. Each style pairs the fade with the single motion that
/// matches the meaning of the swap.
///
/// Reduced motion returns [child] with NO AnimatedSwitcher at all — nothing to settle,
/// nothing to leak.
enum SwapStyle { swap, rise, pop, slideX }

class AnimatedSwap extends StatelessWidget {
  const AnimatedSwap({
    super.key,
    required this.child,
    this.style = SwapStyle.swap,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final SwapStyle style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (!motionEnabled(context)) return child; // no switcher, no controller
    return AnimatedSwitcher(
      duration: CScholarMotion.swap,
      switchInCurve: CScholarCurves.settle,
      switchOutCurve: CScholarCurves.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => _swapTransition(child, animation, style),
      child: child,
    );
  }
}
```

`_swapTransition` composes `FadeTransition` with **one** secondary motion:

| Style | Secondary motion | In / out curve | Use for |
|---|---|---|---|
| `swap` | exiting slides up 0.25 of its height; wrap in `ClipRect` | `settle` / `exit` | hint ↔ error text, label ↔ "Saving…" |
| `rise` | incoming translate Y 0.06 → 0, outgoing → −0.04 | `settle` | skeleton → content |
| `pop` | incoming scale 0.6 → 1.0 | `overshoot` | outline ↔ filled glyph, checkmark, badge |
| `slideX` | incoming from `Offset(-0.12, 0)`, outgoing to `Offset(0.12, 0)` | `settle` | a value changing along a row |

### 5.2 `MorphIcon` — the outline ↔ filled micro-interaction

Used everywhere in CScholar (nav rows, save toggles, status chips) but currently by hard swap.

```dart
/// Outline ↔ filled glyph morph with a springy settle.
///
/// A hard swap is the most common place a Flutter app feels cheap: the eye reads it as a
/// repaint, not a response. The two glyphs cross-fade and scale through
/// [CScholarCurves.overshoot] so the icon *lands*.
///
/// Both glyphs occupy a fixed [size] box, so the swap can never nudge a sibling in the row.
class MorphIcon extends StatelessWidget {
  const MorphIcon({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.color,
    required this.selectedColor,
    this.size = 20,
  });
  // build: AnimatedSwap(style: SwapStyle.pop,
  //   child: Icon(selected ? selectedIcon : icon, key: ValueKey(selected), ...))
}
```

### 5.3 `TactileToggle` — press sink + spring settle + optional burst

The save/bookmark control on `ThesisCard`, `result_card.dart` and `thesis_detail_screen.dart` is the
highest-value micro-interaction in the app: it is the one control a student clicks repeatedly.

```dart
/// A pressable state toggle: sinks on press, springs on release, and optionally fires a
/// one-shot expanding ring on the *activating* transition only.
///
/// The ring plays once and stops — it is NOT a loop, so it needs no ambient gate and
/// `pumpAndSettle()` still terminates. It is decoration layered on the gold
/// [CScholarShadows.goldGlow] already reserved for prestige marks, so high contrast drops
/// it along with the glow.
class TactileToggle extends StatefulWidget {
  const TactileToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.icon,
    required this.selectedIcon,
    this.size = 20,
    this.hitTarget = 40,
    this.burst = true,
    this.haptic = true,
    this.semanticLabel,
  });
  // ...
}
```

Implementation notes:
- press scale `0.94`; release settles on `CScholarCurves.overshoot` over `CScholarMotion.swap`;
- the burst ring is an `AnimatedBuilder` over a one-shot 200ms `CurvedAnimation(curve:
  Curves.easeOut)` drawing `Border.all(color: CScholarMaterial.goldTop)` with opacity `1 - t` and
  scale `0.7 + t * 1.2`, **behind** the glyph, inside the same `RepaintBoundary`;
- `hitTarget` keeps the 40px tap target while the glyph stays 20px (touch-target rule);
- `Semantics(button: true, toggled: selected, label: semanticLabel)` — the existing `PressableSurface`
  already sets the precedent.

### 5.4 `PulseDot` — the live / syncing indicator (ambient)

WayFinder's `PulsingDot`, on 9 elements, with none of the gates CScholar requires.

```dart
/// Breathing status dot: scale 0.85 ↔ 1.15 and opacity 1 ↔ 0.6 on a 1200ms symmetric loop
/// ([CScholarCurves.anticipate] — an asymmetric loop visibly hitches at the turnaround).
///
/// Returns a STATIC dot when [ambientMotionEnabled] is false, so reduced motion, high
/// contrast, low-power and tests get no ticker at all. The caller must wrap its subtree in
/// a [RepaintBoundary]: the loop repaints every frame.
///
/// Three meanings only: live, syncing, recording. A dot that pulses decoratively teaches
/// users to ignore it.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 8});
}
```

### 5.5 `BreathingGlow` — animates the gold halo that already exists

`CScholarMaterial.goldGlow()` is a static three-layer shadow — the only coloured shadow in the
system. Breathing it makes the AI/prestige marks read as *emitting* rather than *tinted*.

```dart
/// Wraps a gold object so its halo slowly deepens and recedes (2400ms, symmetric).
///
/// Only the SHADOW animates. The object is not moved or scaled: a scaled gold tile would
/// break the clay read, and at 200% text it could clip its neighbours. Strength swings
/// between [min] and [max] multiples of [CScholarShadows.goldGlow].
///
/// Decor only, per the material law: 2–3 per screen maximum, never behind text, dropped
/// entirely under high contrast and reduced motion (both make [ambientMotionEnabled]
/// false). Rebuilds via `CScholarMaterial.goldGlow(strength: ...)`, so the recipe keeps one
/// source of truth.
class BreathingGlow extends StatefulWidget {
  const BreathingGlow({super.key, required this.child, this.min = 0.7, this.max = 1.15});
}
```

### 5.6 `DriftingWash` — the hero ambience (ambient)

CScholar's answer to `SoftBlobBackground`, with the constraints WayFinder lacks.

```dart
/// Two slow radial washes drifting behind a hero panel on a 16s loop.
///
/// Placement rules, all of which exist because blur and large radial gradients are the two
/// most expensive things on a Flutter web frame:
///   1. HERO PANELS AND EMPTY STATES ONLY. Never behind a scrolling list, never inside a
///      [ListView] item, never inside a [GlassPanel] (that would force a second backdrop
///      pass), never on a screen that already shows glass chrome at full width.
///   2. At most ONE per screen. Two drifting washes in one viewport is a lava lamp.
///   3. Always fully inside a [RepaintBoundary], and always `IgnorePointer`.
///   4. Colours come from [CScholarMaterial] (e.g. `primaryGreenLight` /
///      `CScholarColors.goldSoft`) at low alpha — never a raw hex, and never gold directly
///      behind text.
///   5. Returns the child alone when [ambientMotionEnabled] is false.
class DriftingWash extends StatefulWidget {
  const DriftingWash({super.key, this.child, this.intensity = 0.28});
}
```

### 5.7 `SkeletonShapes` — skeletons that match the real silhouette

`SkeletonCard` is one rounded rectangle, so swapping to a real `ThesisCard` (76px banner + text
block + tag row) always jumps. Add silhouette skeletons and use them with the existing
`AsyncCrossFade`.

```dart
/// Skeleton with the real card's silhouette: a 76px banner block, two text lines and a
/// short tag row, shimmered in one pass.
///
/// The point is that the CONTENT occupies the same box the skeleton did, so
/// [AsyncCrossFade]'s 8px rise is the only movement at the swap — the page never jumps.
/// Heights are derived from the real card's paddings, not guessed: keep them in sync when
/// [ThesisCard] changes.
class ThesisSkeleton extends StatelessWidget {
  const ThesisSkeleton({super.key, this.bannerHeight = 76});
}
```

Rules: the shimmer sweep duration is `CScholarMotion.shimmer`; the sweep is a moving
`LinearGradient` (sliding `begin`/`end` `Alignment`) rather than a `ShaderMask`, matching
`loading_skeleton.dart`'s existing `Shimmer.fromColors` usage; and the skeleton must be inside the
`AsyncCrossFade` so `asyncSlot` keeps one source for the loading branch.

### 5.8 `ScoreMeter` — the semantic-match percentage

`CScholarSimilarity` classifies a match into four bands, but the badge (`_semanticBadge` in
`thesis_card.dart`) shows a static `%`. A filling meter makes the AI value legible.

```dart
/// Fill-on-first-paint meter for a 0..1 similarity score.
///
/// Two motions, both one-shot: the track fills over [CScholarMotion.page] on [settle], and
/// the numeric label counts up via [CountUpText] so number and bar finish together (a number
/// that lands before its bar looks like a bug).
///
/// The fill colour comes from `CScholarSimilarity.colorFor(score)` so the meter can never
/// disagree with the label, and the fill never renders below 4.5:1 against its track — the
/// existing colorFor tokens are already text-safe on clay.
class ScoreMeter extends StatelessWidget {
  const ScoreMeter({super.key, required this.score, this.height = 6, this.showLabel = true});
}
```

### 5.9 `ScrollVeil` — scroll-linked chrome

The topbar and the repository filter bar are glass, but they look identical scrolled to the top and
scrolled into content. One listener, two behaviours.

```dart
/// Reports whether its child has scrolled past [trigger], and hands the answer to a builder.
///
/// Gives the glass topbar and the repository filter strip a "seated" state: at rest they are
/// flush and rimless; once content passes underneath they gain the glass rim and a deeper
/// shadow. Both are colour/shadow changes over [CScholarMotion.swap] — nothing reflows, which
/// a height-animating collapsing header would.
///
/// **Do not** use it to animate a height. It exists precisely so nobody writes a collapsing
/// header with `AnimatedSize`.
class ScrollVeil extends StatelessWidget {
  const ScrollVeil({
    super.key,
    required this.child,
    required this.builder,
    this.trigger = 12,
  });
  // builder: (context, seated) => Widget
}
```

### 5.10 Hero continuity — thesis card → thesis detail

Today only `userAvatarHeroTag` exists, so `ThesisCard` → `thesis_detail_screen.dart` has no
continuity. Add tags, and honour the rule that a hero needs exactly one source and one target.

```dart
/// Hero tags for thesis continuity. One tag per THING, namespaced by thesis id.
///
/// Two tags exist because a hero must have exactly one source and one target per route
/// change, and a list can show the same thesis twice (results grid + recommendation rail):
///   * [thesisBannerTag] — card banner block → detail header block
///   * [thesisTitleTag]  — card title → detail title
///
/// The match badge deliberately gets NO hero: it is a small colour-coded pill, and flying it
/// while the banner expands reads as two competing motions.
///
/// Disable both on the route that renders the target (`heroBanner: false` on the detail
/// screen's shell call), exactly as `student_layout.dart` takes `heroAvatar: false` for the
/// route that owns [userAvatarHeroTag].
String thesisBannerTag(int thesisId) => 'thesis-banner-$thesisId';
String thesisTitleTag(int thesisId) => 'thesis-title-$thesisId';
```

Also add a `flightShuttleBuilder` on the banner hero so the text inside does **not** fly — only the
coloured slab does. Flying a text block produces smeared, illegible type mid-flight.

### 5.11 Haptics — optional and web-safe

```dart
/// Fire a light selection haptic, but only where it means something.
///
/// [HapticFeedback] is a no-op on web/desktop but still routes through a platform channel, so
/// calling it on every hover costs a message per event. Guard on the platform AND on motion
/// being enabled — a reduced-motion user gets no haptics either, since the two preferences
/// travel together in practice.
void selectionHaptic() {
  if (kIsWeb) return;
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    HapticFeedback.selectionClick();
  }
}
```

---

## PART 6 — Micro-interaction catalogue

"Motion" is what the user sees; "Gate" is what a reduced-motion user gets.

### 6.1 Controls

| Component | File | Motion to add | Gate |
|---|---|---|---|
| Buttons (clay + gel) | `material/neumorph_controls.dart` | Press already sinks. **Add**: release springs back on `overshoot` over `CScholarMotion.swap`; the label ↔ "Saving…" swaps via `AnimatedSwap(style: swap)` while the button keeps its width (never resize under the pointer); a gel button's glow deepens on hover over `micro`. | Sink and label swap instant; static glow |
| Icon buttons | `neumorph_controls.dart` | Glyph rotates 90° (`AnimatedRotation`) for refresh / search-submit actions; press sink as above. | No rotation |
| Fields | `neumorph_field.dart` | Focus ring fades + scales in over `micro`; the placeholder lifts 2px on focus; **error** text replaces the hint via `AnimatedSwap(style: swap)`. Animate the ring's **opacity, not its colour** — a colour tween passes through low-contrast midpoints. | Ring appears instantly, no lift |
| Selects | `neumorph_select.dart` | Menu opens with the **same** 0.96 → 1.0 scale + fade as dialogs, so all floating chrome opens identically; the closed face's caret rotates 180° on open. | Instant |
| Checkboxes / switches | `main.dart` themes | Switch thumb already eases — add an `overshoot` on it; the check glyph scales in with an `AnimatedSwap(style: pop)`. | Instant |
| Chips | `material/clay_objects.dart` (`ClayChip`) | `AnimatedContainer` already cross-fades the fill. **Add**: press sink (`0.96`); a check glyph that pops in on selection **without animating width** — a width animation reflows the whole `Wrap`. Fade/pop the glyph and reserve its slot. | No sink, no pop |
| Nav rows | `common/clay_nav_list.dart` | Pill already glides. **Add**: the selected glyph pops via `MorphIcon`; the focus ring fades in over `micro` instead of appearing. Keep rows fixed-height and the pill un-measured. | Pill snaps (already), glyph static |

### 6.2 Data display

| Component | File | Motion to add | Gate |
|---|---|---|---|
| KPI card | `common/kpi_card.dart` | `CountUpText` already runs. **Add**: `FontFeature.tabularFigures()` so a counting number never reflows its row; a one-shot highlight sweep behind the value when it *changes* (not on first paint); the icon tile floats ±2px on `breathe` via `BreathingGlow` **only** on the gold/AI variant. | No count-up, no sweep, no float |
| Similarity badge | `widgets/thesis_card.dart` → `_semanticBadge` | Use `ScoreMeter` (5.8) on the detail screen; on the card keep the pill, but pulse the `auto_awesome` glyph once when the score lands and let the gold glow breathe. Gold stays ≤ 2–3 per screen, never behind text. | Static pill |
| Status chips | `common/status_chips.dart` | State change cross-fades fill + glyph via `AnimatedSwap(style: pop)`. **No** looping animation — a status is not live. | Instant |
| Progress / loaders | `material/clay_progress.dart` | Already animated. Ensure it sits in a `RepaintBoundary` and its loop is gated by `ambientMotionEnabled`, so a test can still ask the tree to settle. | Static determinate ring |
| Tables / dense rows | admin + faculty screens | Enter on `MotionPitch.tight` with `origin: Offset(0.02, 0)` — a gentle horizontal step, not a vertical cascade (staggering a table vertically makes it unreadable); row hover is a colour change over `micro`, **never** a height change. | Instant |
| Recommendations rail | `widgets/rec_rail.dart` | Enters from `Offset(0.06, 0)` on `MotionPitch.page`; cards inside stagger on `MotionPitch.tight`. | Instant |

### 6.3 Content cards

| Item | Motion | Gate / notes |
|---|---|---|
| `CScholarCard(lift: true)` | Already lifts. **Add**: settle on `CScholarCurves.settle` instead of `standard`, and deepen the shadow in the *same* `AnimatedContainer` as the lift so the two can never disagree. | Desktop/web only; already inert on touch |
| `ThesisCard` banner | A soft radial glow bleeding off one corner (as WayFinder's `NextClassCard` does), breathing on `breathe`; plus the banner `Hero` from 5.10. | Decoration — dropped under high contrast. One glow per card, never behind the title |
| `ThesisCard` hover (web) | Banner scales 1.0 → 1.03 **inside** its own `ClipRRect` so it crops rather than overflows, over `swap`. The most "premium" micro-interaction available and it costs one transform. | No scale under reduced motion |
| `ResultCard` | Same lift, plus a one-shot `EntranceReveal(scaleFrom: 0.98)` staggered on `MotionPitch.result` when a *new* batch replaces an old one. | Instant |
| List re-sort / re-filter | Wrap the result list in `AsyncCrossFade` and stagger its items instead of letting `setState` pop the new list in. A filter change should read as the list *re-forming*. | Instant |
| Save / bookmark | `TactileToggle` (5.3). | Sink only |
| Long abstracts | **Nothing.** Never animate a text block that the user is reading — no parallax, no fade-in per paragraph, no scroll-linked opacity. | — |

### 6.4 Overlays, chrome and pages

| Item | Motion | Gate / notes |
|---|---|---|
| Dialogs | `GlassDialog` is opened by a plain `showDialog`, whose default scale is generic. Route it through one themed `showGeneralDialog` helper (`showClayDialog`) so the glass panel **fades + scales 0.96 → 1** over `CScholarMotion.page` on `settle`, the `scrim` fades in, and the action row staggers by 30ms. Register the transition once in the helper — never hand-roll per call site. | Panel appears instantly; no stagger |
| Sheets | Slide up on `settle` over `CScholarMotion.page`; fade the scrim; keep drag-to-dismiss. | Instant |
| Topbar | `ScrollVeil` (5.9): gains its glass rim and a deeper shadow once content passes under it. | Always seated, no fade |
| Empty state | `EntranceReveal(scaleFrom: 0.96)` for the block; the `ClayIconTile` floats ±2px on `breathe`; the copy does **not** move. | Static, still fully visible |
| Snackbars / toasts | Fade + rise 12px on `settle`; never bounce. | Instant |
| Route transitions | Keep `CScholarTransitionBuilder`, and **add the outgoing half**: wire `secondaryAnimation` so the page being covered fades to 0.9 opacity while scaling to 0.98 as the new page rises in. Layering is what makes a push feel like a push. Cap the whole thing at `CScholarMotion.page`. | Plain swap, no layering |

---

## PART 7 — Screen choreography matrix

The delay map per screen. `S` = `StaggerColumn` child index; all delays are cumulative and clamped by
`MotionPitch.max`. This replaces the current uniform `StaggerColumn` on every screen — the numbers
below are the *design*, so use them rather than re-inventing per screen.

**Universal rule:** the header is `0ms`, the primary hero/action block is `+40ms`, metrics are
`+80ms`, the first list is `+140ms`, and anything below the fold is `+220ms`. Nothing after 240ms
except list items, which step by index and clamp.

| Screen | Choreography |
|---|---|
| `auth/login_screen.dart` | Brand panel enters at 0 (fade only, no rise — it is a full-bleed surface); form fields cascade `MotionPitch.tight`; submit button at 180ms. Wrong-credentials banner replaces the hint via `AnimatedSwap(style: swap)`. |
| `auth/register_screen.dart` | Same as login. The success step is a **new screen state**, so it cross-fades with `AsyncCrossFade`, not a slide. |
| `student/student_dashboard_screen.dart` | Hero greeting (`ClaySurface`) at 0, `scaleFrom: 0.98`; search row `+40`; KPI strip `MotionPitch.feature` with `columns: 3` (diagonal cascade); recent-theses list `MotionPitch.result` starting at `+140`; recommendation rail enters from `Offset(0.06, 0)` at `+220`. `DriftingWash` behind the greeting hero only. |
| `repository/repository_screen.dart` | Hero search (`_hero`) at 0; filter chip `Wrap` cascades `MotionPitch.tight`; results list re-forms on every query change (6.3). Filter strip gains its seated state on scroll. Skeleton = `ThesisSkeleton` × 4. |
| `thesis/thesis_detail_screen.dart` | Banner is the `Hero` **target**, so it must not also fade in (a hero that fades while flying is doubled). Title below it rises at `+60`; abstract `+100`; metadata rows `MotionPitch.tight`; `ScoreMeter` fills at `+140`; related theses `+200`. |
| `student/saved_theses_screen.dart` | Header 0; list `MotionPitch.result`. Removing a saved item plays `TactileToggle`'s reverse and the list re-forms rather than closing a gap instantly. |
| `student/profile_screen.dart` | Avatar is the `Hero` target (already). The rest cascades `MotionPitch.page`. |
| `admin/admin_dashboard_screen.dart` | KPI strip `MotionPitch.feature`, `columns: 4`; two chart cards `+120` and `+180`; activity table `MotionPitch.tight` from `+220`. |
| `admin/*` list + form screens | Header 0; form sections `MotionPitch.page`; tables `MotionPitch.tight` horizontal. |
| `faculty/faculty_dashboard_screen.dart` | As admin. |
| `faculty/faculty_analytics_screen.dart` | Charts draw **after** their card has landed, so give the chart its own `+120ms` delay after its card; do not start a chart draw and a card entrance on the same frame. |
| `design_lab_screen.dart` | Add sections **15 · Motion vocabulary** (every primitive in 5.1–5.11, each in a rest / active row) and **16 · Choreography** (the pitch presets side by side so the difference is visible). This is the review surface for the whole brief. |

---

## PART 8 — Performance law (web is the constraint)

Flutter web is the primary target, so the budget is real. Every rule below is a hard gate:

1. **One-shot motion never exceeds `CScholarMotion.page` (360ms).** If a transition needs longer to feel
   good, the motion is doing too much — split it or drop part of it.
2. **At most 3 loops visible in one viewport**, and at most **one** `DriftingWash` per screen.
3. **Every loop goes inside a `RepaintBoundary`.** The current 5 uses are the standard; a loop without
   one repaints its ancestors every frame.
4. **Blur is shared, never stacked.** Use `GlassGroup` around a screen with several glass layers, and
   never put a `DriftingWash` behind a `GlassPanel` — it forces a second backdrop pass, and a wash is
   invisible through `.62` white anyway.
5. **Offstage tickers are muted.** `TickerMode(enabled: ...)` is the pattern WayFinder uses for inactive
   tabs; apply it wherever a screen keeps looping content alive behind a route or tab.
6. **No animation on a `ListView` item's geometry.** Animate the item's transform/opacity, never the
   `ListView`'s layout.
7. **No `Opacity` widget where a colour's alpha will do** — `Opacity` forces a save-layer. Prefer
   `AnimatedContainer` / `Color.withValues(alpha:)` for a single element; use `FadeTransition` only for
   real cross-fades.
8. **Dispose everything.** Every new `State` with a controller disposes it. No exceptions, and no
   `AnimationController` created in `build`.
9. **No `Timer`.** If something must tick (a relative timestamp, "synced 2m ago"), use a `Ticker` like
   WayFinder's countdown, so no timer is left pending and it pauses with the frame clock.
10. **Profile before and after.** Capture a `flutter run --profile` timeline for the repository screen
    and the student dashboard before Phase 1 and after Phase 8. A raster-time regression on those two
    screens is a task failure, not a tradeoff.

---

## PART 9 — Accessibility law

1. **Reduced motion = inert.** Covered in PART 0.2 #3 and enforced by `motion_test.dart`. Add one test
   per new primitive (PART 10).
2. **High contrast = static.** New ambient primitives must consult `ambientMotionEnabled`, which already
   returns false under high contrast.
3. **Never convey information by motion alone.** A pulsing dot needs its text label ("Syncing…"), a
   filling meter needs its number, a colour-coded chip needs its word.
4. **Focus is never animated away.** The `ClayNavList` focus ring exists and must stay; new rings fade
   in but must be **fully opaque at their end state** and stay `1px`/`2px` at `rimStrong` strength (or
   the `gelTop` ring the nav list uses).
5. **Keyboard path survives.** `Focus` / `onKeyEvent` on any new pressable; `MorphIcon` and
   `TactileToggle` are labels plus `Semantics`, not gestures alone.
6. **Text scaling to 200% is a test case, not a hope.** Every animation must be a no-op for layout, so
   200% text can never be clipped by a "nice" scale or lift. The `screens_render_test.dart` matrix
   (both sizes × high contrast × 100%/200% text) already enforces this — do not weaken it.
7. **No flash risk.** Anything animating opacity must end at 1.0 and must not animate a large bright
   area from 0 → 1 in under 120ms (WCAG 2.3.1).
8. **Do not animate a colour across a contrast floor.** Animate the opacity of a fixed-contrast layer
   instead — the midpoint of a colour tween is where AA gets broken.

---

## PART 10 — Tests

### 10.1 Existing tests must keep passing **unchanged**

`material_system_test.dart`, `tier1_surface_test.dart`, `tier2_surface_test.dart`,
`tier3_controls_test.dart`, `screens_render_test.dart`, `widget_test.dart`,
`neumorph_select_test.dart` — treat a failure here as a real regression, not a test to update. Three
specific traps:

- `motion_test.dart` pins `CScholarDurations.slow == 300ms` and `EntranceReveal.duration <=
  CScholarDurations.slow`. **Do not change `CScholarDurations`.** That is exactly why the new budget
  lives in a separate class.
- `motion_test.dart` asserts `Stagger(index: 50)` clamps to a **240ms** delay. So
  `MotionPitch.page.max` must stay `240ms`, and the default `Stagger`/`StaggerColumn` behaviour must be
  byte-identical to today's.
- `screens_render_test.dart` uses a frame budget, not `pumpAndSettle()`. Keep it that way, and add
  `CScholarMotion.ambientEnabled = false;` to its `setUpAll` so new loops cannot slow the matrix — it
  generates **176 cases** (22 screens × 2 sizes × 2 contrast levels × 2 text scales) from a single
  `testWidgets`.

### 10.2 `motion_test.dart` — cases to add

```
▢ ambient gate ON: PulseDot / DriftingWash / BreathingGlow schedule frames (a ticker exists).
▢ ambient gate OFF: the same three widgets settle — assert `tester.binding.hasScheduledFrame ==
  false` after a 2s pump, so no ticker is left running.
▢ ambient gate OFF via high contrast and via reduced motion: same static, settled result.
▢ AnimatedSwap under reduced motion returns the child with NO AnimatedSwitcher in the tree.
▢ AnimatedSwap normally: after swapping the child, BOTH children are present mid-flight (a real
  cross-fade, not a hard swap).
▢ MorphIcon: on the frame after selection changes, the incoming glyph is scaled below 1.0 (proves the
  overshoot exists).
▢ TactileToggle: press moves the surface (transform != identity); the burst controller completes and
  STOPS (pumpAndSettle terminates — the ring must never loop).
▢ TactileToggle under reduced motion: no transform, no burst.
▢ Budget: every new one-shot constant is <= CScholarMotion.page.
▢ StaggerColumn(pitch:) clamps at that pitch's max for a 50th child, for all four pitches.
▢ StaggerColumn(columns: 3): child 3's delay > child 1's delay (the diagonal cascade is real).
```

### 10.3 `a11y_motion_test.dart` (new, recommended)

Render the repository screen at high contrast with `ambientEnabled = true` and assert no ticker was
scheduled — i.e. prove the high-contrast path kills the ambience, rather than trusting the gate that
was written for it.

### 10.4 Manual review (run `flutter run -d chrome`, then `--profile`)

```
▢ /design-lab open, sections 15 and 16 present.
▢ Toggle reduced motion: every new primitive is static and nothing throws.
▢ Toggle high contrast: no halo, no wash, no glow, no pulse.
▢ Text scale 200%: nothing clipped, nothing overlapping.
▢ Student dashboard → repository → thesis detail → back: banners fly, no double-drawn title, the
  page underneath fades rather than vanishing.
▢ With 40 results: scroll and type; frame time stays flat and no shimmer keeps running after load.
```

---

## PART 11 — Rollout order

One phase per commit. Each phase ends with `flutter analyze` clean and `flutter test` green.

> **Position when this doc was last updated (2026-10-05): ALL eight phases are complete and
> committed** (`905f72f` … `6073cc9`) — nothing in this table remains to be done. Per-phase commit
> hashes are in **PART R.1**; post-run verification is in **PART R.7**.

| Phase | Deliverable | Files |
|---|---|---|
| **1 · Foundation** | `CScholarMotion`, extended `CScholarCurves`, `MotionPitch`, `ambientMotionEnabled`, `selectionHaptic`. `Stagger` / `StaggerColumn` / `EntranceReveal` gain their optional params. **Zero visual change yet** — verify by comparing screenshots of every screen before/after. | `core/constants/cscholar_constants.dart`, `common/motion.dart` |
| **2 · Primitives** | `AnimatedSwap`, `MorphIcon`, `TactileToggle`, `PulseDot`, `BreathingGlow`, `DriftingWash`, `ThesisSkeleton`, `ScoreMeter`, `ScrollVeil`, hero tags. Demoed in design-lab sections 15 + 16. New `motion_test.dart` cases. | `common/motion.dart` (+ `motion_ambient.dart`), `common/loading_skeleton.dart`, `screens/design_lab_screen.dart`, `test/motion_test.dart` |
| **3 · Chrome & navigation** | Sidebars (`MorphIcon` glyphs, ring fade), topbar (`ScrollVeil`), route transition gains its outgoing half, dialog + sheet transitions unified. | `clay_nav_list.dart`, `topbar.dart`, `faculty_topbar.dart`, `admin_topbar.dart`, `common/motion.dart` |
| **4 · Controls** | Buttons, icon buttons, fields, selects, chips, checkboxes/switches (PART 6.1). | `neumorph_controls.dart`, `neumorph_field.dart`, `neumorph_select.dart`, `clay_objects.dart`, `main.dart` |
| **5 · Dashboards** | Choreographed entrances (PART 7) + KPI micro-motion + `DriftingWash` behind the student greeting hero. | `student_dashboard_screen.dart`, `admin_dashboard_screen.dart`, `faculty_dashboard_screen.dart`, `kpi_card.dart` |
| **6 · Repository & results** | Result list re-forms on query change, `ThesisSkeleton`, filter-strip seated state, scroll behaviour. | `repository_screen.dart`, `result_card.dart`, `rec_rail.dart`, `thesis_card.dart` |
| **7 · Thesis detail & save** | Banner + title `Hero`, `ScoreMeter`, `TactileToggle` on save, related-list stagger. | `thesis_detail_screen.dart`, `thesis_card.dart`, `saved_theses_screen.dart`, `profile_screen.dart` |
| **8 · Polish & proof** | Empty states, snackbars, analytics chart delay; re-profile; update any design doc the repo keeps; final manual review. | remaining screens |

**Definition of done** = every box in PART 12 checked, `flutter analyze` clean, `flutter test` green,
and the Phase 8 profile showing no raster-time regression on the repository screen or the student
dashboard.

---

## PART 12 — Acceptance checklist

Copy this into the PR description and tick every line.

```
FOUNDATION
▢ CScholarDurations is UNCHANGED (fast 150 / normal 250 / slow 300 / debounce 400).
▢ CScholarMotion + MotionPitch + ambientMotionEnabled exist, with doc comments.
▢ CScholarCurves gained settle/overshoot/exit/anticipate/steady; standard + entrance unchanged.
▢ EntranceReveal, Stagger, StaggerColumn gained OPTIONAL params only; existing call sites unchanged.

PRIMITIVES
▢ 10 new primitives exist (5.1-5.10) and all are demoed in /design-lab.
▢ Every new primitive is inert under reduced motion (a test proves it, per primitive).
▢ Every looping primitive returns a static equivalent when ambientMotionEnabled is false.
▢ Every looping primitive sits inside a RepaintBoundary.
▢ Every State that owns a controller disposes it; no controller is created in build.

CHOREOGRAPHY
▢ No screen relies on the bare default StaggerColumn any more - each uses a named MotionPitch.
▢ Grids cascade diagonally (columns > 1) rather than left-to-right.
▢ Every page enters header-first, then hero, then metrics, then list.

MICRO-INTERACTIONS
▢ Save/bookmark = TactileToggle (sink + spring + one-shot burst that stops).
▢ Outline<->filled glyphs go through MorphIcon; no hard icon swaps remain in nav rows or toggles.
▢ Buttons keep their width when their label changes (no resize under the pointer).
▢ Focus rings fade in and end fully opaque; focus/keyboard paths intact.
▢ Counting numbers use FontFeature.tabularFigures().

CONTINUITY
▢ Thesis card -> thesis detail flies the banner and title; the flight shuttle does not fly the text.
▢ heroBanner: false is set on the route that owns the target, as student_layout does for the avatar.
▢ The covered page fades/scales out rather than vanishing.

GUARDRAILS
▢ No new colour, fill, gradient or shadow was invented outside CScholarMaterial.
▢ Gold appears on <= 2-3 elements per screen and never behind text.
▢ High contrast: no blur, no gradient, no coloured shadow, no loop anywhere.
▢ 200% text: nothing clipped, nothing overlapping (screens_render_test matrix still passes).
▢ No new dependency in pubspec.yaml, and no Timer was introduced.
▢ flutter analyze clean; flutter test green; profile shows no raster regression.
```

---

## PART 13 — Explicit do-not list

```
x Do NOT restyle, recolour, re-radius, re-shadow or re-lay-out anything.
x Do NOT change CScholarDurations or the existing CScholarCurves values.
x Do NOT add an animation package (no flutter_animate, no rive, no lottie).
x Do NOT animate layout: no AnimatedSize on list items, no collapsing header via animated height,
  no animated Padding/width inside a scrolling list, no animated item heights in a ListView.
x Do NOT animate a text block the user is reading (no per-paragraph fades, no scroll-linked opacity
  over an abstract).
x Do NOT stack blur: no DriftingWash behind a GlassPanel, no second backdrop group.
x Do NOT let a loop run without a gate, a RepaintBoundary and a disposal path.
x Do NOT put a spring/overshoot on anything larger than ~80px.
x Do NOT animate a colour through a low-contrast midpoint, and never animate white-on-gold into
  existence.
x Do NOT delete or re-sign existing helpers, screens or tests - extend them.
x Do NOT add motion just to satisfy the brief. Every animation must answer one of two questions:
  "what did the user just do?" or "what state is the app in right now?". An animation that answers
  neither is a distraction and will be reverted in review.
```

---

## Kickoff message for the agent

**A. Starting from scratch** (historical — the repo is already past this point, so use B):

> Read `docs/DESIGN_IMPROVEMENT_PROMPT.md` in full before writing any code.
>
> Implement it in the 8 phases of PART 11, one commit per phase, in order. Phase 1 must produce
> **zero visual change** — it only adds tokens and optional parameters.
>
> Before Phase 1: run `flutter analyze` and `flutter test` inside `frontend/` and paste both results,
> so we have a clean baseline to compare against.
>
> For every phase: run `flutter analyze` + `flutter test`, and report exactly which PART 12 checklist
> lines that phase completes. After Phase 2, describe design-lab sections 15 and 16 screen by screen
> so I can approve the motion vocabulary before you apply it anywhere.
>
> If any requirement conflicts with the code you find, stop and tell me instead of choosing.

**B. The run is complete — verify, do not re-do** (this is the case the repo is in — use this one):

> Read **PART R** of `docs/DESIGN_IMPROVEMENT_PROMPT.md` first. Phases 1–8 are all committed
> (`905f72f` … `6073cc9`) — do **not** redo any phase or re-litigate the vocabulary.
>
> First: `cd frontend` and run `flutter analyze` + `flutter test`, and paste both results. Expected:
> analyze clean, **290 tests pass** (the tree was verified green at `6073cc9` on 2026-10-05). If
> either fails, stop and report before changing anything.
>
> If both are green, the brief in this document is **done** — say so and stop (PART R.7). Only if
> explicitly asked to add motion beyond it: re-read PART 5, PART 6 and PART 7 for the rules, keep
> every gate, `RepaintBoundary` and disposal path, never touch `CScholarDurations` or
> `motion_test.dart`, one commit per change, and if anything in the brief conflicts with the code
> you find, stop and tell me instead of choosing.