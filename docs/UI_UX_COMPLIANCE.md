# CScholar — UI/UX compliance

Implementation report for [`UI_UX_IMPLEMENTATION_RULES.md`](UI_UX_IMPLEMENTATION_RULES.md).
Status values follow Appendix B: **Done**, **Partial**, **N/A**, **Deferred**,
**Deviation**. A rule is only **Done** when the implementation site and a
verification are named.

Last verified: 2026-11-25.

## Commands

| Check | Command | Result |
|---|---|---|
| Format | `cd frontend && dart format lib test` | clean |
| Analyze | `cd frontend && flutter analyze` | **No issues found** |
| Tests | `cd frontend && flutter test` | **496 passing** |
| Backend compile | `cd backend && python -m compileall app` | clean |

New rule tests live in [`frontend/test/ui_ux_rules_test.dart`](../frontend/test/ui_ux_rules_test.dart)
and [`frontend/test/layout_breakpoints_test.dart`](../frontend/test/layout_breakpoints_test.dart).
Existing coverage that these changes rely on: `theme_mode_test.dart`,
`screens_render_test.dart`, `motion_test.dart`, `focus_ring_test.dart`,
`mobile_auth_test.dart`, `tier1_surface_test.dart`, `tier2_surface_test.dart`,
`tier3_controls_test.dart`, `result_card_layout_test.dart`,
`saved_theses_mobile_filter_test.dart`, `student_mobile_shell_test.dart`.

## What changed in this pass

1. **Tap targets** — added `CScholarTapTarget` (`frontend/lib/core/constants/cscholar_constants.dart`).
   `NeumorphIconButton` now clamps every icon action to 44×44
   (`neumorph_controls.dart`); the 32×24 password reveal, sheet close buttons,
   pagers, card save toggles, header avatar/chrome, theme switch, breadcrumbs,
   filter pills and result-card actions now meet the floor.
2. **Accessible names and roles** — tooltips on every raw `IconButton`
   (filters, keyword clear, password reveal, back actions); `Semantics` on the
   mobile save toggle, avatar, filter pickers and status chips; nav rows and
   tabs announce `selected`.
3. **Programmatic field labels** — `NeumorphField` and `MobileAuthField` attach
   their visual label to the field's semantics node and exclude the duplicate
   text; errors are polite live regions (`A11Y-12`, `A11Y-14`).
4. **Honest errors** — `frontend/lib/core/utils/user_facing_error.dart` maps
   status codes to actionable copy. Every screen-level error slot and snackbar
   that used `err.toString()` now uses it; raw `ApiException(...)` no longer
   reaches users.
5. **Recoverable failures** — retry added to the blocking error states
   (thesis detail, recommendations, faculty/admin dashboards, faculty/admin
   thesis forms, programs/advisers, saved studies, profile, admin users).
6. **Status vocabulary** — one canonical spoken label plus icon per thesis
   status (`status_chips.dart`), role/active helpers in
   `frontend/lib/core/utils/vocabulary.dart`, used by detail rows, settings and
   chips.
7. **Empty-state recovery** — repository now separates “empty library” from
   “filters matched nothing”; faculty theses, admin analytics, users, profile,
   dashboard lists and the faculty edit lock each offer a next action.
8. **Destructive actions** — publish/archive on a single thesis, discarding a
   bulk-import preview, and both thesis-form cancels now confirm and name the
   consequence; a shared `confirmDiscardChanges` protects typed work.
9. **Session + deep links** — `ApiService` reports an authenticated 401 once;
   `AuthNotifier.sessionExpired()` clears the local session and the router
   returns to sign-in. Unauthenticated deep links carry `?from=` and are
   restored after sign-in; unknown/invalid links land on a role-appropriate
   list instead of a bare error.
10. **Theme** — with no saved choice the app now starts in the OS mode
    (light/dark), still remembering an explicit toggle.
11. **No fabricated data** — the profile’s hard-coded “12 Viewed / 3 Topics”
    and “Alex Santos / BS Computer Science” fallbacks were replaced with real
    values or explicit “Email not provided”.

## Rule status

### 1. Design system

| Rule | Status | Implementation / verification |
|---|---|---|
| DS-1 | Done | Single token layer: `core/constants/cscholar_constants.dart`, `core/material/material_tokens.dart`, `cscholar_palette.dart`. Screen code reads tokens; `tier2_surface_test.dart`. |
| DS-2 | Done | Semantic roles in `CScholarPalette` (paper/surface/soft/ink/muted/hairline/accent/action/danger/scrim). `theme_mode_test.dart` flips every role. |
| DS-3 | Done | Light/dark palettes in `cscholar_palette.dart`; dialogs/sheets/toasts themed in `main.dart`; first launch follows OS (`CScholarModeStore.load`). `theme_mode_test.dart`, `theme_transition_test.dart`. |
| DS-4 | Done | Named scales in `CScholarTextStyles` / `CScholarMobileTextStyles`; mobile error copy raised from 10.5 to 12. `tier1_surface_test.dart`, `screens_render_test.dart`. |
| DS-5 | Done | Body styles carry 1.5/1.6 line-height; reading surfaces are max-width capped in shells. |
| DS-6 | Done | Weight hierarchy in the type tokens; labels stay 500–700, display 700–800. |
| DS-7 | Done | `CScholarRadius` + `CScholarMobileRadius`; no per-surface radius sets added. |
| DS-8 | Done | `CScholarMaterial.cardShadow` / `gelDrop` / `overlay`; `neumorph_controls` and `clay_surface`. |
| DS-9 | Done | One green accent + coral attention/error; no new accents added. |
| DS-10 | Done | Shared `NeumorphButton`, `NeumorphField`, `NeumorphSelect`, `EmptyState`, `ClayPagination`, `GlassDialog`; `tier3_controls_test.dart`. |
| DS-11 | Done | `ThesisStatusStyle` (label + colour + icon), `CScholarColors.statusFill`, `roleLabel`/`activeLabel`/`thesisStatusLabel`. `ui_ux_rules_test.dart`. |
| DS-12 | Done | Removed fake profile metrics and name/email fallbacks; unknown values render explicit copy. |

### 2. Accessibility

| Rule | Status | Implementation / verification |
|---|---|---|
| A11Y-1 | **Partial** | 44×44 enforced for icon buttons, reveal, sheet close, pagers, avatar, save toggles, theme switch, breadcrumbs, filter pills, result-card actions (`ui_ux_rules_test.dart`). Not yet audited: every table row action and every `ClayChip` call site. |
| A11Y-2 | Done | Palette pairs measured in `theme_mode_test.dart`; new status/label colours reuse measured pairs. |
| A11Y-3 | Done | Status chips carry text + semantic label; `ThesisStatusStyle.icon` supplies the shape where a visual icon is used; errors pair icon + text. |
| A11Y-4 | **Partial** | Custom icon buttons always pass `tooltip`; raw `IconButton`s now have tooltips; mobile save/avatar/pickers named. No compile-time required label yet. |
| A11Y-5 | Done | `button`/`enabled` on `_NeumorphBase`; `selected` on nav rows/tabs; switches/checkboxes keep Material state. |
| A11Y-6 | Done | `Status: Published`, `Role: Faculty`, `Account status: Active`, picker label+value read as one node. `ui_ux_rules_test.dart`. |
| A11Y-7 | N/A | No legal/consent control in the product today. |
| A11Y-8 | Done | `focus_ring_test.dart`; keyboard focus rings preserved. |
| A11Y-9 | **Partial** | Material controls are keyboard reachable; the full primary flow has not been manually keyboard-walked in this pass. |
| A11Y-10 | **Partial** | 200% text matrix passes (`screens_render_test.dart`); 320px reflow now tested for the primary flows (`layout_breakpoints_test.dart`); mobile nav grows with text scale. No in-app text-size setting exists. |
| A11Y-11 | Done | `motion.dart` gates every helper; `motion_test.dart`, `theme_transition_test.dart` (instant swap). |
| A11Y-12 | Done | `NeumorphField` / `MobileAuthField` label semantics + error below field; `ui_ux_rules_test.dart`. |
| A11Y-13 | **Partial** | Heading order is manually maintained; no web skip link (Flutter web semantics only). |
| A11Y-14 | Done | `AuthErrorBanner`, `MobileAuthError`, field errors are live regions; `ui_ux_rules_test.dart`. |

### 3. Responsive layout

| Rule | Status | Implementation / verification |
|---|---|---|
| LAY-1 | **Partial** | Primary flows (auth, dashboard, repository, saved, profile) now run at 320 and 768 at 100%/150% (`layout_breakpoints_test.dart`); admin/faculty screens are covered at 400/1440 by `screens_render_test.dart`, not yet at 320. |
| LAY-2 | Done | `AuthShell.maxCardWidth`, role shells cap content; `page_header_alignment_test.dart`. |
| LAY-3 | Done | `MediaQuery.sizeOf` / `CScholarBreakpoints`, no device detection. |
| LAY-4 | Done | Bottom nav (4 destinations) below breakpoint, persistent sidebars above; `student_mobile_shell_test.dart`. |
| LAY-5 | **Partial** | Data tables scroll in containers; column strategy is existing, not re-audited this pass. |
| LAY-6 | Done | `SafeArea` in shells, auth corner, route error page, bottom sheets. |
| LAY-7 | **Partial** | Forms scroll; dialogs fit; pinned actions exist in forms. Keyboard overlay not re-tested. |
| LAY-8 | **Partial** | Long strings ellipsize in cards/rows; not every metadata surface has a longest-string test. |
| LAY-9 | Done | Wizard nav pinned in mobile register; critical header above fold. |
| LAY-10 | **Partial** | Nav/header now scale with text; other fixed-height illustrations remain intentionally fixed. |
| LAY-11 | Done | Responsive gutters in shells and cards. |

### 4. Navigation

| Rule | Status | Implementation / verification |
|---|---|---|
| NAV-1 | Done | Four student destinations; admin/faculty sidebar groups; `student_mobile_shell_test.dart`. |
| NAV-2 | Done | Depth screens hide the bottom nav; `student_mobile_shell_test.dart`. |
| NAV-3 | **Partial** | Back routes are explicit; modal close first; forms confirm discard. Desktop shell back uses `go` rather than `pop`. |
| NAV-4 | **Partial** | Providers preserve data and filters; scroll offsets are not explicitly persisted. |
| NAV-5 | Done | Role-aware 404 and invalid-id page (`routeErrorPage`), `?from=` restored after sign-in. |
| NAV-6 | **Partial** | One fade+rise transition for every route; peer tabs do not slide. |
| NAV-7 | **Partial** | Flutter route transitions paint both pages during the animation; outgoing page fades/scales under the incoming one. |
| NAV-8 | **Partial** | Detail returns to the role list, not a fixed home; notification origin flow does not exist. |
| NAV-9 | Done | Server route guards (`backend/app/routes/*`), router role redirects; `student_mobile_guard_test.dart`. |
| NAV-10 | Done | Rows are tappable with one open action. |
| NAV-11 | Done | Pointer cursor only on interactive chrome. |

### 5. Motion

| Rule | Status | Implementation / verification |
|---|---|---|
| MOT-1 | Done | `motion.dart` / `animate_x.dart`; transform/opacity/colour only. |
| MOT-2 | Done | `CScholarMotion` budgets (120/200/280/360). `motion_test.dart`. |
| MOT-3 | Done | `CScholarCurves` (settle/entrance/exit/overshoot). |
| MOT-4 | Done | `AnimatedScale`/press sinks + `selectionHaptic`. |
| MOT-5 | Done | Hover uses colour/border/shadow; no size change. |
| MOT-6 | Partial | Hover is per-control; no shared list hover owner. |
| MOT-7 | Done | No hover-induced layout animation. |
| MOT-8 | Done | `motionEnabled`/`ambientMotionEnabled` + tests. |
| MOT-9 | Done | `Stagger` capped at 240ms. |
| MOT-10 | Done | Progress/pill transitions are continuous. |
| MOT-11 | Done | Theme iris is the one deliberate reveal; reduced motion swaps instantly. |

### 6. Loading / empty / error / offline

| Rule | Status | Implementation / verification |
|---|---|---|
| STA-1 | Done | `DeferredSkeleton` holds 250ms; `loading_skeleton.dart`. |
| STA-2 | Done | Shaped `ThesisSkeleton` reserves the real card box; `AsyncCrossFade`. |
| STA-3 | **Partial** | Repository, saved, faculty theses, users and analytics distinguish states with recovery actions; some dashboard panels still have simple “nothing yet” copy. |
| STA-4 | **Partial** | Retry added to every blocking error path audited; a few small inline panels remain text-only by design (e.g. a recommendation strip has Retry). |
| STA-5 | **Deferred** | No offline outbox. The app is read-mostly; long-form submission drafts are the candidate. Needs product decision on stored payloads (PDF bytes). |
| STA-6 | **Deferred** | Follows STA-5. |
| STA-7 | **Deferred** | No submission retry queue. Server create endpoints remain non-idempotent; adding a client token needs a product/backend decision. |
| STA-8 | **Partial** | Auth 401 keeps the page’s typed form state (no navigation until the router redirects); draft persistence on expiry is not implemented. |
| STA-9 | Done | Riverpod refresh keeps data; `asyncSlot` skips skeletons on refresh. |
| STA-10 | Done | Explicit refresh shows the real loading branch. |
| STA-11 | Done | Shared `RefreshIndicator` styling; `faculty_theses`/repository. |
| STA-12 | **Partial** | Providers dispose; no live-poll queue exists to poll. |
| STA-13 | **Partial** | Activity feeds use `relativeTime`; “last updated” is not shown. |

### 7. Forms

| Rule | Status | Implementation / verification |
|---|---|---|
| FRM-1 | **Partial** | Mobile register is 2 steps; desktop register and thesis forms are still one card (under 20 fields). |
| FRM-2 | **Partial** | Steps preserve values; thesis forms have no review step. |
| FRM-3 | Done | Actions sit below the scrolling form, visible at the card edge. |
| FRM-4 | Done | `autovalidateMode.onUserInteraction` + submit validation; inline errors. |
| FRM-5 | **Partial** | Single-step forms; server field errors are mapped for thesis/user forms where possible. |
| FRM-6 | **Partial** | No scroll-to-first-invalid helper yet. |
| FRM-7 | Done | Autovalidate clears on correction; banners clear on retry. |
| FRM-8 | Done | Email/password keyboards, autofill hints on auth fields. |
| FRM-9 | **Partial** | No phone/government ID inputs exist; Student ID is collected but not sent (needs backend support or removal). |
| FRM-10 | **Partial** | Date pickers clamp where used; not every date entry is typed+picker. |
| FRM-11 | Done | Login/register/change-password reveal toggles, confirmation, min 6; `ui_ux_rules_test.dart`, `change_password_dialog_test.dart`. |
| FRM-12 | N/A | No OTP flow. |
| FRM-13 | **Partial** | PDF type/size shown, per-file upload state; no remove/retry queue for bulk import. |
| FRM-14 | N/A | No consent checkbox in the product. |
| FRM-15 | N/A | No CAPTCHA. |
| FRM-16 | **Partial** | Adviser is derived for faculty; city/province/age do not exist. |
| FRM-17 | **Partial** | `confirmDiscardChanges` wired to both thesis forms; register step-back preserves input; browser reload is not guarded. |

### 8. Feedback and destructive actions

| Rule | Status | Implementation / verification |
|---|---|---|
| FB-1 | Done | Field error → inline; success/failure → snackbar; decision → dialog; page failure → `EmptyState`. |
| FB-2 | Done | All success toasts follow `await`; no optimistic writes. |
| FB-3 | Done | Publish/archive, delete, deactivate, discard preview, discard form. |
| FB-4 | **Partial** | Destructive bulk actions confirm; no undo. |
| FB-5 | Done | `_isSubmitting`/`_starting`/`_saving` guards. |
| FB-6 | Done | Failed submits keep form input and show actionable copy. |
| FB-7 | **Partial** | Bulk status reports updated/skipped; other partial failures are not surfaced as a count. |
| FB-8 | Done | One floating snackbar style; dismiss target inherits 44px Material. |
| FB-9 | Done | Errors requiring a decision use dialogs; messages use snackbars. |

### 9. Content

| Rule | Status | Implementation / verification |
|---|---|---|
| CNT-1 | Done | Plain-language pass on auth/error copy. |
| CNT-2 | Partial | Shared empty/error copy for the major surfaces; some bespoke dashboard copy remains. |
| CNT-3 | Done | Every new empty/error state has a next action. |
| CNT-4 | Done | `user_facing_error.dart`; no `err.toString()` remains in `lib/presentation`. |
| CNT-5 | Done | Specific labels (“Reset all filters”, “Publish”, “Keep editing”). |
| CNT-6 | Done | Role/shell and profile identity show scope; role labels centralized. |
| CNT-7 | Partial | `relativeTime` in feeds; profile still uses a numeric member-since date. |
| CNT-8 | Partial | Removed fake values; not every unset optional field shows “Not provided”. |
| CNT-9 | Done | Verb-first 1–3 word buttons. |
| CNT-10 | Partial | Reference/status text is not ellipsized; some metadata still truncates. |

### 10. Trust and privacy

| Rule | Status | Implementation / verification |
|---|---|---|
| TRU-1 | Done | Server validation and authorization in `backend/app`; client validation is UX only. |
| TRU-2 | Done | Router hides routes; backend 403/401 enforced (`auth.py`, route dependencies). |
| TRU-3 | Done | Login returns “Invalid credentials” for unknown AND deactivated accounts; recovery copy is generic. Registration still reports an existing account (outside the rule’s login/recovery/lookup scope) so the user can sign in. |
| TRU-4 | **Partial** | Authenticated 401 clears the session and returns to sign-in; no pre-expiry warning or “stay signed in” refresh yet. |
| TRU-5 | N/A | No consent/notice flow. |
| TRU-6 | Partial | `relativeTime` converts to local; thesis detail date formatter still needs a `.toLocal()` audit. |
| TRU-7 | Done | Mutations invalidate the list and detail providers. |
| TRU-8 | Done | Role shell and identity blocks show ownership. |
| TRU-9 | Partial | Status history is not displayed as a timeline. |

### 11. Platform

| Rule | Status | Implementation / verification |
|---|---|---|
| PLT-1 | Done | Tap targets, safe areas, haptics (`selectionHaptic`), no hover-only critical actions. |
| PLT-2 | Done | Pointer cursor, hover/focus, keyboard activation. |
| PLT-3 | Done | No mobile splash on web. |
| PLT-4 | **Partial** | GoRouter controls history; list rows use `go` rather than `push`, so browser Back exits to the previous top-level location. |
| PLT-5 | Partial | Form values survive rebuilds; scroll offsets not persisted. |
| PLT-6 | Done | Native pickers/file picker/date picker used. |

### 12. Perceived performance

| Rule | Status | Implementation / verification |
|---|---|---|
| PERF-1 | Done | Skeletons reserve layout; `result_card_layout_test.dart`. |
| PERF-2 | Done | `asyncSlot` keeps data on refresh; no skeleton flash. |
| PERF-3 | **Partial** | Riverpod caches reads; no explicit in-flight request dedupe layer. |
| PERF-4 | Done | No decorative asset blocks the first frame. |
| PERF-5 | Partial | Token restore happens before runApp; first-screen data is not prewarmed. |
| PERF-6 | Done | Lists paginate (10/page). |
| PERF-7 | Done | `ClayPagination` page size, totals, disabled ends. |

## Anti-patterns

| Anti-pattern | Status |
|---|---|
| Icon-only button with no name | Fixed for audited controls; no compile-time guarantee yet. |
| Placeholder-only label | Fixed (`NeumorphField`, `MobileAuthField`). |
| Status by colour only | Fixed (text + semantic label + icon token). |
| Text below 12px that must be read | Fixed (errors raised to 12). |
| Tap targets below 44 | Fixed across audited controls; not exhaustively audited. |
| Skeleton flash | Fixed (`DeferredSkeleton`). |
| Skeleton without reserved space | Fixed (shaped skeletons). |
| Empty state with no recovery | Fixed on repository, saved, faculty/admin lists, profile, analytics. |
| Filtered-empty indistinguishable from empty | Fixed in repository, users, faculty theses. |
| Error with no retry | Fixed on blocking paths; a few inline strips remain. |
| Silent failure / success before server | Fixed on audited paths. |
| Destructive without confirmation | Fixed for publish/archive/discard/delete. |
| Losing typed data on back/expiry | Partially fixed (form cancel guard); no local draft. |
| 20+ fields in one column | No such form. |
| Server field errors not on the field | Partial. |
| Offline copy claiming submission | N/A (no offline mode). |
| Duplicate submissions | Guarded by in-flight disable; no idempotency key. |
| Desktop sidebar squeezed into phone | No. |
| Horizontal scroll at 320px | Not verified. |
| Table causing page horizontal scroll | No; tables own their scroll. |
| Two full pages during transition | Flutter cross-fades both pages during a route change (documented deviation). |
| Theme wipe ignoring reduced motion | Fixed/tested. |
| “Good morning” at 8 PM | Fixed (`<12 / <17 / else`). |
| Raw ISO timestamps | No. |
| Mock values presented as real | Fixed on profile. |
| Auth error reveals account existence | Fixed for login; registration still states an existing account so the user can sign in. |
| Unauthorized action hidden but server allows | No; server guards every route. |

## Remaining MUST work (needs a decision)

These are the only MUST-level gaps left after this pass. Each needs either a
product decision or a larger feature:

1. **STA-5/6/7 — offline drafts/outbox.** Long forms (faculty/admin thesis)
   still require a connection. A local draft is feasible with
   `SharedPreferences` for text fields; the attached PDF bytes and an
   idempotency key need a backend contract. Suggested next step: text-only
   draft autosave + honest “Saved on this device” banner, and a server
   idempotency key for create.
2. **TRU-4 — pre-expiry warning / stay signed in.** The JWT is 24h. Add
   `/api/auth/refresh`, decode `exp` on the client, warn 5 minutes before, and
   extend on confirmation.
3. **A11Y-1/A11Y-4 completeness.** Run a semantics-tree audit across every
   screen (including table row actions) and add a lint-style test that fails on
   any unnamed tap target.
4. **LAY-1 completeness.** Primary flows now run at 320/768. Extend the same
   check to admin/faculty screens; dense table rows are the likely clip points.
5. **NAV-6/NAV-7/PLT-4 history semantics.** Decide whether list → detail should
   `push` (browser Back returns to the list) or stay on `go` (Back exits to the
   previous top-level location). This is a navigation-model decision, not a
   styling one.
6. **FRM-9 Student ID.** Registration collects a Student ID but the backend
   register payload has no field for it. Either add it (schema is locked; see
   `users` columns) or remove the input. Recommend removing the input until the
   API supports it.
7. **CNT-7/TRU-6 date formatting.** Finish converting every displayed timestamp
   through one local-time formatter; today only activity feeds use
   `relativeTime`.
