# Personalized "Recommended for You" (no new tables)

| Field | Value |
|---|---|
| Date | 2026-11-20 |
| Defense | 2026-12-04 |
| Status | **Built and verified** |
| Scope | Student home dashboard recommendation card |
| Schema impact | **None.** No table, no column, no index added or removed. |
| Model | Content-based, anchored on the student's **last action** |

## 1. What ships

The card answers one sentence: *"You viewed/saved X, so here is what is closest
to X."*

- **Anchor** = the last study the student acted on. Opening a thesis sets it to
  `viewed`; saving a thesis sets it to `saved`. Un-saving does not change it.
- Opening a different thesis **re-anchors**, so the four rows change on the next
  dashboard visit.
- The anchor lives on the device (`SharedPreferences`); the server receives one
  id and ranks against that study's embedding.
- No history yet → newest four published, captioned "New in the repository".

```
detail opened ──► recommendationAnchorProvider (id + 'viewed', device)
save toggled  ──► recommendationAnchorProvider (id + 'saved', device)
dashboard     ──► POST /api/recommendations { saved_ids | viewed_ids: [id] }
              ◄── { personalized, basis: 'Because you viewed "X"', items }
```

Server side, unchanged from the earlier build:

1. lead chunk of the anchor thesis (lowest-id embedding)
2. cosine rank over published theses, anchor excluded
3. straight similarity order — the same ranking the detail rail uses
4. similarity floor 0.35; leftover slots filled with newest, labelled "New"
5. one `recommendation_logs` row per thesis shown (FR-17)

The weighting code (`saved ×2`, averaged profile) is still present in the
backend but is no longer reached from the dashboard, because the UI sends a
single source. It can serve a multi-source profile later without a schema
change.

## 2. Where each thing lives

| Data | Storage | Notes |
|---|---|---|
| Anchor (id + viewed/saved) | device (`SharedPreferences`) | survives a reload; per device, not per account |
| Saved theses | device (`SharedPreferences`) | unchanged; saving also re-anchors the feed |
| Search queries | existing `search_logs` (table 15) | written by `POST /api/embeddings/search` |
| Impressions | existing `recommendation_logs` (table 16) | the only write the recommender performs |

The 2 operational tables (`thesis_reviews`, `import_jobs`)
are not touched by this feature.

## 3. UI behaviour

- Heading: "Recommended for You".
- Caption from the server: **Because you viewed "X"** or **Because you saved
  "X"**; "New in the repository" when there is no anchor.
- Each row: title, `Program • 81% match` at score ≥ 0.50, otherwise
  `Program • New` / `Program • Related` with a neutral pill.
- Tapping a row passes the score to the detail screen, so the match meter only
  appears when a real similarity was computed.
- Errors show "Recommendations unavailable"; an empty catalogue shows "No
  recommendations yet".
- "View All" still goes to `/repository`.

## 4. Honest limitations (say these at the defense)

- The feed is **not a learned profile**. It is content-based retrieval seeded by
  the student's last action. Say "seeded by your last action", not "trained on
  your behaviour".
- It is **per device**, not per account.
- It is the same algorithm as "Related research" on the detail page, which is a
  feature (one concept, two entry points), not a shortcut.
- `% match` is cosine similarity to the anchor study, not a probability.
- There is **no diversity pass**: rows are simply the closest first, which can
  cluster on one topic. That was a deliberate trade for a ranking that matches
  the detail rail and is trivial to explain.
- Cold start shows newest records, clearly labelled, never padded with low
  scores.

## 5. Verification performed

- `flutter analyze`: clean.
- `flutter test`: **369/369**, including 5 cases in
  `frontend/test/recommendations_provider_test.dart`: view anchors, save
  re-anchors, unsave keeps the anchor, restored anchor is sent, local action
  beats a slow restore.
- `python -m compileall backend/app`: clean.
- Live API with a student token: one source id returns
  `basis: 'Because you viewed "…"'`, four rows at 0.82–0.89, source excluded;
  impression rows written and then removed after the test.

## 6. Files changed

| File | Change |
|---|---|
| `backend/app/models.py` | `recommend_for_profile`, `mmr_pick`, `log_recommendations`, `log_search`, vector helpers |
| `backend/app/routes/thesis.py` | `POST /api/recommendations` |
| `backend/app/routes/embedding.py` | semantic search logs to `search_logs` |
| `backend/app/schemas.py` | `RecommendationRequest` |
| `frontend/.../providers.dart` | anchor persistence, `recommendationsProvider` |
| `frontend/.../student_dashboard_screen.dart` | personalized card, caption, reason labels |
| `frontend/.../thesis_detail_screen.dart` | re-anchors on open (and on id change) |
| `frontend/.../admin_settings_screen.dart` | dead recommendations toggle removed |
| Docs | `DESIGN.md`, `demo_script_20261204.md`, `plan_20261120.md` copy aligned |
