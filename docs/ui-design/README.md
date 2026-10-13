# CScholar — IT110 Lab Activity 6: UI Design Package (v2.0, Oct 2026)

> Supersedes `docs/ui_wireframes.html` (v1) for Lab 6 purposes. v1 = single-width screens only.
> v2 = full rubric package: flow + responsive wireframes + widget/state + routes + validation + states + accessibility + review log.

## Files

| File | Purpose |
|---|---|
| `index.html` | **Primary deliverable.** Open in browser → print/screenshot. Contains: system identity, Part A traceability, UI-flow diagram, Part C route map (from `lib/core/router/app_router.dart`), Part B screen inventory + widget/state plan, Part D desktop wireframes (S01–S09) + 390/768/1440 variants for S03 Search, S04 Detail, S07 Upload, Part E components + consistency guide, Part F validation plan, Part H state matrix, Part G accessibility checklist, Part J review log. |
| `../../ui_wireframes.html` | v1 history (low-fi phones). Keep, do not submit as Lab 6. |

## Coverage vs rubric (80 pts)

- Traceability 10: Part A table FR-01…FR-20 → screens/actions/states.
- Navigation 10: Part C route table with guards; unknown-route + session-expiry behavior.
- Responsive 15: all major screens @1440 + S03/S04/S07 @390/768/1440, no uncontrolled overflow.
- Widget/components 10: Part B + Part E; Stateless vs Stateful vs Riverpod-shared distinguished.
- Forms/states 10: Part F + Part H; disabled/submitting; retry-safe.
- Accessibility 8: Part G checklist.
- Consistency/docs 7: stable IDs S01…S09, route labels, versioned folder.
- Review 10: Part J log + reflection prompts; each member explains assigned screens.

## How to submit

1. Open `index.html` → Print to PDF (flow + wireframes) and screenshot frames.
2. Fill member names, block, date in banner; fill Part J during review.
3. Commit `docs/ui-design/` → submit as `IT110_LA6_CScholar` via MasaoLMS/Classroom.
