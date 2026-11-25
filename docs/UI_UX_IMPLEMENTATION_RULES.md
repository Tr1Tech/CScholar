# UI/UX Implementation Rules

**A portable, testable specification for AI coding agents.**

Use this file as the UI/UX contract for any web, mobile, desktop, or cross-platform app. Every rule is written as a directive so an agent can implement it, and every rule has an acceptance check so a reviewer can verify it.

**Levels**

- **MUST** — release blocker. Do not ship without it.
- **SHOULD** — expected. Skip only with a written product reason.
- **MAY** — optional enhancement.

---

## How to use this file with an AI agent

Paste this block at the start of the task, then attach or reference this file:

```text
You are implementing UI/UX for <APP NAME> using UI_UX_IMPLEMENTATION_RULES.md.

Operating rules:
1. Read the entire spec before editing code.
2. Map every MUST rule to a concrete file/component in this codebase.
3. Reuse the existing design-token layer. Do not introduce raw colours, font sizes,
   spacing values, radii, or shadows outside it.
4. When a rule conflicts with the existing design system or product constraints,
   STOP and ask. Do not silently pick a side.
5. Every MUST rule that affects interaction, accessibility, layout, or state must
   get a regression test that fails without the change.
6. Do not batch unrelated fixes. One logical change per commit.
7. Do not claim a rule is implemented unless you can name the file and the test.

Final deliverable:
- A compliance table: Rule ID | Status (done/partial/not applicable) | File(s) | Test(s)
- The exact commands used to run lint, type-check, and tests, with results.
- A short list of any rule you intentionally deviated from, with the reason.
```

**Definition of done for the whole task**

- [ ] No new raw design values outside the token layer.
- [ ] Every interactive target is at least 44×44 CSS px.
- [ ] Text contrast and type sizes pass the accessibility section.
- [ ] Every async surface has loading, empty, error, and offline states.
- [ ] Every destructive action is confirmed or undoable.
- [ ] Layout works at 320, 390, 768, 1024, and 1440 CSS px.
- [ ] The primary flows are completable with keyboard only.
- [ ] The primary flows are comprehensible with a screen reader.
- [ ] Reduced-motion mode is respected.
- [ ] Every MUST rule has a test or a documented manual check.

---

## 1. Design system and visual consistency

- **DS-1 (MUST)** Use a single token layer for colour, typography, spacing, radius, shadow, and motion.
  *Done when:* no screen file contains raw hex colours, magic font sizes, or one-off spacing that bypasses the tokens.
- **DS-2 (MUST)** Define semantic colour roles, never colour literals, in product UI: `canvas`, `surface`, `surface-raised`, `ink`, `ink-muted`, `border`, `primary`, `on-primary`, `danger`, `danger-soft`, `success`, `warning`, `focus-ring`, `scrim`.
  *Done when:* swapping the palette changes every screen without editing screen code.
- **DS-3 (MUST)** Ship light and dark palettes, and make “follow system” the default.
  *Done when:* dialogs, sheets, menus, snackbars, inputs, tables, and empty states all follow the palette — no white flash when a modal opens in dark mode.
- **DS-4 (MUST)** Use one type scale. Minimum sizes: body 14–16px, secondary 12–13px, uppercase micro-labels ≥10px. Never use tiny text for information the user must read.
  *Done when:* every text style maps to a named scale step, and no body copy is below 12px.
- **DS-5 (MUST)** Set body line-height to 1.4–1.6 and keep line length around 45–75 characters on reading surfaces.
- **DS-6 (MUST)** Use one weight hierarchy. Reserve the heaviest weight for display titles, key values, primary buttons, active navigation, and status badges — not for every label.
- **DS-7 (MUST)** Use a small radius scale (e.g. 8/12/16/24) consistently; do not mix arbitrary corner radii in the same surface.
- **DS-8 (MUST)** Use one shadow/elevation language. Cards, inputs, hover states, and modals each have one treatment.
- **DS-9 (SHOULD)** Prefer restrained colour. Use an accent colour for state or emphasis, not decoration. Do not add extra accent colours per screen.
- **DS-10 (MUST)** Reuse one component per pattern (button, field, chip, card, empty state, error state, dialog, pager).
  *Done when:* the same concept looks and behaves identically on every screen.
- **DS-11 (MUST)** Keep status vocabulary centralized. A status has one canonical key, one display label, one colour role, and one icon across chips, tables, filters, timelines, and notifications.
- **DS-12 (SHOULD)** Never invent values to fill a layout. Unknown fees, dates, counts, or instructions render as “To be confirmed”, “Not available”, or are omitted — never as fake data.

---

## 2. Accessibility

- **A11Y-1 (MUST)** Every interactive target is at least **44×44 CSS px**; primary actions should be at least 48px tall.
  *Done when:* icon buttons, pagers, filter chips, search-clear buttons, inline text links, and close buttons all meet the floor with their hit area, not just their glyph.
- **A11Y-2 (MUST)** Every text and background pair meets WCAG AA: **4.5:1** for normal text, **3:1** for large text (≥24px, or ≥18.66px bold) and for meaningful UI boundaries/graphics.
  *Done when:* the palette is tested programmatically, including tinted surfaces and dark mode.
- **A11Y-3 (MUST)** Never use colour as the only carrier of meaning. Pair status colours with text and a distinct icon or shape.
- **A11Y-4 (MUST)** Every icon-only control has an accessible name.
  *Done when:* a semantics/accessibility-tree audit reports zero unnamed tap targets. Prefer making the label a required prop or lint rule, not a convention.
- **A11Y-5 (MUST)** Announce role and state: buttons are buttons, tabs announce `selected`, toggles announce checked, disabled controls announce disabled.
- **A11Y-6 (MUST)** Group compound information into one semantic unit where reading every child would be noise. Example: a status chip reads “Status: Processing”, not “Processing” plus an unlabeled icon plus a dot.
- **A11Y-7 (MUST)** Legal or consequential controls name their consequence. A consent checkbox says what it agrees to; it does not rely on a separate sentence beside it.
- **A11Y-8 (MUST)** Provide a visible focus indicator with at least 3:1 contrast against the adjacent background. Never remove focus outlines without an equivalent replacement.
- **A11Y-9 (MUST)** The full primary flow is operable with keyboard only, in a logical focus order, with no keyboard trap.
- **A11Y-10 (MUST)** Support text zoom and OS font scaling:
  - Support at least 200% text zoom without loss of content or function.
  - Reflow at 320 CSS px width without horizontal scrolling (except data tables, which scroll inside their own container).
  - If the app offers an in-app text-size setting, combine it with the OS setting rather than replacing it, and clamp the total so fixed furniture does not break.
- **A11Y-11 (MUST)** Respect reduced-motion. Disable non-essential motion, parallax, auto-playing loops, and full-screen transitions.
- **A11Y-12 (MUST)** Form inputs have programmatic labels. Place labels above the field; place error text below the field. Do not use placeholders as the only label.
- **A11Y-13 (SHOULD)** Provide a skip link or landmark structure on web; keep heading levels ordered.
- **A11Y-14 (SHOULD)** Announce asynchronous status changes (saved, failed, retrying) through a polite live region or equivalent, without stealing focus.

---

## 3. Responsive layout

- **LAY-1 (MUST)** Design mobile-first and verify at **320, 390, 768, 1024, and 1440 CSS px**.
  *Done when:* no horizontal page scroll, no clipped controls, and no overlapping text at any breakpoint.
- **LAY-2 (MUST)** Cap reading width. Mobile shells may be full-bleed; tablet/desktop content should use a comfortable max width (e.g. 520px for phone-shaped flows, 640–760px for forms, 1200–1440px for dashboards).
- **LAY-3 (MUST)** Use layout breakpoints, not device detection. A narrow desktop window gets the compact layout; a wide tablet gets the expanded one.
- **LAY-4 (MUST)** Choose a navigation pattern by available width: bottom navigation or a drawer below the breakpoint; persistent sidebar above it. Do not squeeze a desktop sidebar into a phone.
- **LAY-5 (MUST)** Data tables either fit, or scroll horizontally inside a container with a minimum readable width. Never crush columns into ellipsis soup.
- **LAY-6 (MUST)** Respect safe areas: status bar, notch, home indicator, and rounded corners. Paint backgrounds edge-to-edge, but keep controls inside the safe area.
- **LAY-7 (MUST)** Handle the on-screen keyboard: scrollable forms, dialogs that fit the remaining viewport, pinned primary actions that stay reachable, and no content hidden behind the keyboard.
- **LAY-8 (MUST)** Long content must degrade gracefully: flex or ellipsize names, emails, reference numbers, addresses, and labels. Test the longest realistic string, not the sample data.
- **LAY-9 (SHOULD)** Keep critical content above the fold on small screens, and pin wizard navigation outside the scroll region.
- **LAY-10 (SHOULD)** Avoid fixed heights that assume one text size. If a layout must be fixed (e.g. a kiosk home screen), compute a fit budget and fall back to scrolling when it cannot fit.
- **LAY-11 (SHOULD)** Use responsive gutters (e.g. 16 / 26 / 38px) instead of one desktop gutter on every width.

---

## 4. Navigation and interaction

- **NAV-1 (MUST)** Limit top-level mobile destinations (3–5). More than five belongs in a “More” surface.
- **NAV-2 (MUST)** Sub-pages do not show the top-level navigation bar if they have their own back action and sticky actions. Do not stack competing navigation.
- **NAV-3 (MUST)** Define back behaviour explicitly:
  - Sub-page → its parent page.
  - Non-start tab → the start tab.
  - Modal/drawer → close the modal/drawer first.
  - Form with unsaved work → confirmation before discarding.
  - Top-level start page → allow the OS/app to exit.
- **NAV-4 (MUST)** Preserve user state on back/navigation: scroll position, filters, form values, and the selected record.
- **NAV-5 (MUST)** Deep links resolve to a valid screen. If the target is missing or deleted, fall back to the nearest valid list with an explanation.
- **NAV-6 (MUST)** One navigation transition per hierarchy level: peer tabs cross-fade; entering a sub-page pushes forward; leaving slides back. Do not slide between sibling tabs.
- **NAV-7 (MUST)** Never render two full pages at once during a transition. Animate the outgoing page away, swap, then animate the incoming page in.
- **NAV-8 (MUST)** Preserve the origin of secondary flows. Opening notifications from “My Requests” returns to “My Requests”, not a fixed home tab.
- **NAV-9 (MUST)** Route by authorization on the server, not by a client-side persona toggle. The signed-in role decides the shell.
- **NAV-10 (SHOULD)** Give every list row a single, obvious open action; the entire row should be tappable where practical.
- **NAV-11 (SHOULD)** Use pointer cursor and hover affordance only on genuinely interactive controls.

---

## 5. Motion and interaction feedback

- **MOT-1 (MUST)** Animate only purposeful transitions: state change, spatial relationship, or feedback. Do not animate decoration that does not communicate.
- **MOT-2 (MUST)** Keep micro-interactions fast: 120–200ms for press/hover, 200–300ms for small reveals, 300–450ms for page transitions.
- **MOT-3 (MUST)** Use one easing language. A single ease-out curve for entrances and a faster curve for exits is enough.
- **MOT-4 (MUST)** Press feedback must survive a quick tap. Hold the pressed frame for a minimum beat (e.g. 140ms) so the scale/colour change is perceptible, and add a light haptic on supported devices.
- **MOT-5 (MUST)** Hover must not move the widget. A widget that shifts under the cursor causes enter/exit flicker. Use colour, border, or shadow only.
- **MOT-6 (MUST)** Maintain a single hover owner in a list. A fast pointer sweep must not leave several rows looking hovered at once.
- **MOT-7 (MUST)** Never animate layout properties if a transform/opacity alternative exists. Avoid hover-induced layout shift.
- **MOT-8 (MUST)** Disable non-essential motion under reduced-motion, including startup animations and full-screen theme wipes.
- **MOT-9 (SHOULD)** Stagger list entrances by a small step (40–80ms) and keep the total under ~500ms.
- **MOT-10 (SHOULD)** Make progress transitions continuous. A step indicator should fill/drain smoothly rather than pop.
- **MOT-11 (SHOULD)** Make theme changes feel intentional: either instant or a single deliberate reveal from the control that triggered it. Never animate an unsolicited OS theme change as a full-screen effect.

---

## 6. Loading, empty, error, and offline states

Every data surface MUST implement all applicable states below. A screen with only a success state is incomplete.

- **STA-1 (MUST)** **Loading:** show a skeleton or spinner only after a short delay (≈300ms). A fast response must not flash a placeholder.
  *Done when:* a cached/sub-100ms fetch renders content directly, with no skeleton frame.
- **STA-2 (MUST)** **Skeleton quality:** reserve the final layout space so content does not jump when it arrives. Prefer shaped skeletons over a blank spinner for lists and cards.
- **STA-3 (MUST)** **Empty:** distinguish three situations and give each one sentence, used consistently everywhere:
  - *No match* — a search/filter is narrowing and found nothing. Always offer the action that clears the narrowing.
  - *Nothing yet* — the list is genuinely empty. Offer the action that starts the task when one exists.
  - *Empty page* — an otherwise non-empty list has no rows on this page. Offer a way back to a valid page.
- **STA-4 (MUST)** **Error:** show a human-readable message and a retry action. Never leave a blank screen or an unhandled exception.
- **STA-5 (MUST)** **Offline:** support a local draft/outbox where the task allows it. Show a persistent, dismissible-only-when-safe banner, keep the draft visible in the list, and retry automatically on a timer, on app resume, and on explicit retry.
- **STA-6 (MUST)** Offline copy must be truthful: “Saved on this device — waiting for internet”, never “Submitted”. Swap to the real reference only after the server accepts it.
- **STA-7 (MUST)** Make submissions idempotent (stable client token/idempotency key) so a retry after a lost response does not create duplicates.
- **STA-8 (MUST)** Never discard a user’s draft because of an expired session. Keep it, explain that sign-in is needed, and resume after sign-in.
- **STA-9 (MUST)** Background refresh must be quiet: bust the cache, compare the payload, and rebuild only when data actually changed. Do not replay skeletons or entrance animations every poll.
- **STA-10 (MUST)** User-triggered refresh must be loud: show the real loading state, then the fresh data.
- **STA-11 (MUST)** Pull-to-refresh must be consistent across every pullable surface and use the app’s palette, not platform-default chrome.
- **STA-12 (MUST)** Refresh on app resume and on a sensible poll interval for live queues/notifications; stop timers on dispose.
- **STA-13 (SHOULD)** Show “last updated” or equivalent for live data, and make it clear when a number is stale.

---

## 7. Forms and input

- **FRM-1 (MUST)** Split long forms into short, meaningful steps. A wall of 20+ fields should become a wizard with a visible step count (“Step 2 of 6”).
- **FRM-2 (MUST)** Each step has one idea. Back never clears a value. The final step reviews everything and links back to the step that owns each field.
- **FRM-3 (MUST)** Pin Back/Next outside the scroll area so the primary action is never below the fold.
- **FRM-4 (MUST)** Validate inline on blur/submit. Show the error next to the field, keep the label visible, and use a clear message that says how to fix the problem.
- **FRM-5 (MUST)** On a multi-step form, a server field error jumps to the step that owns the field and focuses or scrolls to it.
- **FRM-6 (MUST)** Scroll to the first invalid field on submit. A summary banner alone is not enough when the field is off-screen.
- **FRM-7 (MUST)** Clear a field error as soon as the user starts fixing that field, and clear the summary banner when no errors remain.
- **FRM-8 (MUST)** Use the right input type and keyboard: email, tel, number, date, password. Provide `autocomplete`/`autofill` hints for identity, address, and payment fields.
- **FRM-9 (MUST)** Preserve and normalize input where it helps:
  - Phone numbers: accept common shapes, normalize to one canonical form before sending.
  - Government/issuer IDs: format to the issuer’s groups while typing.
  - Codes that are case-sensitive: uppercase as typed when that prevents an invisible mismatch.
  - Do not reformat in a way that moves the caret unexpectedly on every keystroke.
- **FRM-10 (MUST)** Dates: offer a picker, allow typed entry, and clamp the picker range. A typed out-of-range date must open the picker, never crash.
- **FRM-11 (MUST)** Passwords: show/hide toggle, live strength or requirement feedback, a confirmation field, and the server’s minimum policy. Do not cap at an unreasonably short length.
- **FRM-12 (MUST)** One-time codes: validate length, show a resend countdown, and disable resend until it expires.
- **FRM-13 (MUST)** File uploads: state accepted types and max size before the picker, validate before uploading, show per-file state (ready, uploading, failed, remove/retry).
- **FRM-14 (MUST)** Consequential consent is an explicit checkbox, not implied by submission. Link to the full notice and record the accepted version.
- **FRM-15 (MUST)** A CAPTCHA or human-verification widget must fit its container; open it in a sized dialog rather than clipping an inline frame.
- **FRM-16 (SHOULD)** Do not ask for what the system already knows. Derive city/province from the selected barangay/locality, derive age from birthdate, and show derived values as read-only text with an Edit link.
- **FRM-17 (SHOULD)** Warn before losing typed work (navigation, reload, back, sign-out) and offer “Keep editing” / “Discard”.

---

## 8. Feedback and destructive actions

- **FB-1 (MUST)** Choose the lightest feedback that fits:
  - Inline field error for a field problem.
  - Snackbar/toast for a transient success or non-blocking failure.
  - Dialog for a decision or an irreversible action.
  - Full error state for a page that cannot load.
- **FB-2 (MUST)** Never report success before the server confirms it. Optimistic UI is allowed only when rollback and error messaging are implemented.
- **FB-3 (MUST)** Destructive actions require confirmation that names the consequence (“This saved request was never sent, so deleting it cannot be undone.”).
- **FB-4 (MUST)** Prefer undo over confirmation for reversible bulk actions. If undo is not possible, confirm.
- **FB-5 (MUST)** Disable the triggering control while an action is in flight, and guard against double submission.
- **FB-6 (MUST)** A failed action must leave the user where they were, with their input intact, and tell them what to do next.
- **FB-7 (MUST)** A partial failure must be honest: “Nothing was marked read” is better than a silently half-applied state.
- **FB-8 (SHOULD)** Use one toast position and one toast style app-wide; make dismiss a 44px target.
- **FB-9 (SHOULD)** Do not use a toast for an error that requires a decision. Do not use a modal for a message that needs no decision.

---

## 9. Content and copy

- **CNT-1 (MUST)** Use plain language. Prefer short sentences, active voice, and the user’s words over internal jargon.
- **CNT-2 (MUST)** One situation, one sentence, everywhere. The same empty/error/success state must not be worded differently on two screens.
- **CNT-3 (MUST)** No dead ends. Every empty, error, or filtered state offers the next action or the way out.
- **CNT-4 (MUST)** Errors say what happened, why if known, and what to do next. Never blame the user. Never expose raw stack traces, status codes, or database messages.
- **CNT-5 (MUST)** Use specific, human labels. “Start review” beats “Submit”; “Move to Ready for Pickup” beats “Update”.
- **CNT-6 (MUST)** Explain the local context. Show the active organization/location/account when an action could be scoped to the wrong one.
- **CNT-7 (SHOULD)** Use time-aware copy (morning/afternoon/evening, “today”, “2 days ago”) where it helps, and absolute timestamps where precision matters.
- **CNT-8 (SHOULD)** Label unknown or unset values explicitly (“To be confirmed”, “Not provided”) rather than leaving a blank.
- **CNT-9 (SHOULD)** Keep button labels verb-first and 1–3 words. Keep confirmation button labels specific to the action.
- **CNT-10 (SHOULD)** Do not truncate meaning. Ellipsize decorative metadata, but never a required instruction, reference number, or error.

---

## 10. Trust, privacy, and data handling

- **TRU-1 (MUST)** The server is authoritative. Client validation exists for UX only; never rely on it for security or correctness.
- **TRU-2 (MUST)** Hide actions the user cannot perform, but enforce the same rule on the server. UI hiding is not authorization.
- **TRU-3 (MUST)** Do not reveal whether an account exists during login, recovery, or lookup. Use generic messages.
- **TRU-4 (MUST)** Warn before an idle session expires and offer “Stay signed in”. Make the timeout visible and enforced server-side.
- **TRU-5 (MUST)** Record explicit consent with the notice version, and make the notice reachable before consent.
- **TRU-6 (MUST)** Convert server timestamps correctly. Treat zone-less timestamps as UTC (or the documented server zone), convert to local, and format human-readably.
- **TRU-7 (MUST)** Never show a stale value as current. Invalidate caches after a mutation, and refresh dependent screens.
- **TRU-8 (SHOULD)** Show ownership/scope: which organization, branch, barangay, workspace, or account the data belongs to.
- **TRU-9 (SHOULD)** Make status history auditable: show the pipeline, timestamps, actor, and remarks where the user is allowed to see them.

---

## 11. Platform conventions

- **PLT-1 (MUST)** Mobile: tap targets, safe areas, haptics where supported, and no hover-only affordances.
- **PLT-2 (MUST)** Desktop/web: pointer cursor on interactive elements, visible hover and focus states, keyboard activation for buttons/links, and no touch-only gestures for critical actions.
- **PLT-3 (MUST)** Do not show a mobile cold-boot splash on web/desktop page loads. Platform-appropriate loading only.
- **PLT-4 (MUST)** Respect browser/app back and forward navigation; do not trap history.
- **PLT-5 (SHOULD)** Preserve scroll and form state across route changes where the platform expects it.
- **PLT-6 (SHOULD)** Use native platform controls where they are better understood (date picker, file picker, share sheet) rather than rebuilding them poorly.

---

## 12. Perceived performance

- **PERF-1 (MUST)** Avoid layout shift. Reserve space for images, skeletons, banners, and async content.
- **PERF-2 (MUST)** Prefetched/cached data must render without a skeleton flash on return navigation.
- **PERF-3 (MUST)** Deduplicate identical in-flight requests and cache idempotent reads for the session where safe.
- **PERF-4 (MUST)** Keep animations off the critical path. Do not block the first useful frame on decorative assets.
- **PERF-5 (SHOULD)** Warm the first screen’s data during startup/sign-in so the handoff lands on content, not a spinner.
- **PERF-6 (SHOULD)** Virtualize or paginate long lists; do not render thousands of rows.
- **PERF-7 (SHOULD)** Paginate predictably: fixed page size, “Page N of M · total”, disabled arrows at the ends, and no tappable dead pages.

---

## 13. Anti-patterns — reject these

If an implementation contains any of these, it is not done:

- Icon-only buttons with no accessible name.
- Placeholder used as the only field label.
- Status communicated only by colour.
- Text below 12px that the user must read.
- Tap targets below 44×44.
- Hover effects that move or resize the element.
- Skeleton flash on fast/cached loads.
- Skeleton that does not reserve layout space.
- Empty state with no recovery action.
- Filtered-empty state that looks identical to “you have no data”.
- Error state with no retry.
- Silent failure, or a success toast before the server confirms.
- Destructive action without confirmation or undo.
- Losing typed form data on back, refresh, or session expiry.
- A form with 20+ fields in one column and no steps.
- Server field errors that do not land on the field that caused them.
- Offline copy claiming data was submitted when it was only saved locally.
- Duplicate submissions after a retry.
- A desktop sidebar squeezed into a phone width.
- Horizontal page scroll at 320px.
- A page that scrolls horizontally because a table has no container strategy.
- Two full pages visible at once during a route transition.
- A full-screen theme wipe or startup animation that ignores reduced-motion.
- “Good morning” shown at 8 PM.
- Raw ISO timestamps shown to users.
- Mock/fake values presented as real data.
- Auth errors that reveal whether an account exists.
- Hiding an unauthorized action in the UI while the server still allows it.

---

## 14. Verification checklist

### Automated

- [ ] Contrast test for every palette pair, light and dark.
- [ ] Semantics/accessibility-tree test: zero unnamed tap targets on every screen.
- [ ] Tap-target test: every interactive rect ≥44×44 on the target viewports.
- [ ] Layout tests at 320, 390, 768, 1024, 1440.
- [ ] Text-zoom test at 200% and at the largest in-app step.
- [ ] Reduced-motion test: transitions land instantly.
- [ ] Loading test: fast fetch never reveals the skeleton.
- [ ] Empty-state test: no-match offers recovery; nothing-yet offers start; empty page offers a way back.
- [ ] Error-state test: retry is present and calls the loader again.
- [ ] Offline test: draft survives restart, retries with the same idempotency key, and never claims submission.
- [ ] Navigation test: back from sub-page/tab/modal/form follows the defined hierarchy.
- [ ] Pagination test: page changes reset to a valid page and scroll to top.
- [ ] Form test: server field errors land on the owning field/step.
- [ ] Destructive-action test: confirmation appears and cancellation preserves state.

### Manual

- [ ] Complete the primary task with keyboard only.
- [ ] Complete the primary task with a screen reader on.
- [ ] Complete the primary task at 200% zoom.
- [ ] Complete the primary task with reduced motion enabled.
- [ ] Complete the primary task with the network disabled mid-flow.
- [ ] Complete the primary task on the smallest supported width.
- [ ] Inspect dark mode on every modal, sheet, menu, toast, and empty state.
- [ ] Inspect the longest realistic names, emails, addresses, and reference numbers.
- [ ] Verify no layout shift when data replaces skeleton.
- [ ] Verify back does not discard work.

---

## Appendix A — Reference implementation map

These are the concrete files and tests from the BarangayFlow codebase that this spec was derived from. Treat them as a reference implementation, not a requirement; adapt names and paths to the target stack.

| Concern | Reference |
|---|---|
| Design tokens (type, radius, motion, shadow) | `lib/theme/app_tokens.dart` |
| Semantic light/dark palette | `lib/theme/app_colors.dart` |
| Text scale, theme persistence | `lib/theme/app_settings.dart` |
| Shared buttons, fields, press/hover, loading delay, live refresh mixins | `lib/widgets/common.dart` |
| Empty/error states and status chips | `lib/widgets/async_widgets.dart` |
| Resident shell, headers, bottom nav, 44px icon buttons | `lib/widgets/phone_shell.dart` |
| Hierarchy-aware page transitions | `lib/widgets/page_through.dart` |
| Pull-to-refresh chrome | `lib/widgets/pull_refresh.dart` |
| Request status timeline | `lib/widgets/status_timeline.dart` |
| Offline outbox banner | `lib/widgets/sync_banner.dart` |
| Theme reveal + reduced-motion handling | `lib/widgets/theme_reveal.dart` |
| Idle-session warning | `lib/widgets/idle_guard.dart` |
| Six-step registration, secure auth, OTP, recovery | `lib/screens/resident/secure_auth.dart` |
| Form validation, server-error mapping, discard guard | `lib/screens/resident/resident_flow.dart` |
| Lists, search recovery, pagination, profile edit | `lib/screens/resident/resident_lists.dart` |
| Home fit-without-scroll layout | `lib/screens/resident/resident_home.dart` |
| Staff responsive shell, back handling, review actions | `lib/screens/staff/staff_app.dart` |
| Staff table, sidebar hover, chrome | `lib/screens/staff/staff_chrome.dart` |
| Staff queue, review, empty states | `lib/screens/staff/staff_pages.dart` |
| Offline drafts and retry rules | `lib/offline/offline_sync.dart`, `lib/offline/request_draft.dart` |
| Contact number normalization | `lib/api/contact_number.dart` |
| Server timestamp conversion | `lib/widgets/common.dart` (`parseServerStamp`) |
| Accessibility name tests | `test/accessibility_names_test.dart` |
| Tap-target tests | `test/tap_target_test.dart` |
| Empty vocabulary tests | `test/empty_vocabulary_test.dart` |
| List + search recovery tests | `test/list_recovery_test.dart` |
| Form recovery tests | `test/form_recovery_test.dart` |
| Navigation/back tests | `test/navigation_back_test.dart` |
| Loading-delay tests | `test/delayed_loading_test.dart` |
| Live refresh tests | `test/live_refresh_test.dart` |
| Offline outbox tests | `test/offline_outbox_test.dart` |
| Status visual consistency tests | `test/status_visuals_test.dart` |
| Theme/reduced-motion tests | `test/theme_reveal_test.dart`, `test/splash_test.dart` |
| Responsive home tests | `test/resident_home_layout_test.dart` |
| Security/auth UX tests | `test/secure_auth_test.dart` |

## Appendix B — Severity guide for agent reports

When reporting compliance, use this scale:

| Status | Meaning |
|---|---|
| **Done** | Rule implemented, with file and test named. |
| **Partial** | Some surfaces comply; list the exceptions. |
| **N/A** | Rule does not apply to this product; state why. |
| **Deferred** | Rule accepted but scheduled later; include the ticket/owner. |
| **Deviation** | Deliberate departure; include the product reason and approver. |

An agent must never mark a rule **Done** without naming the implementation site and the verification.
