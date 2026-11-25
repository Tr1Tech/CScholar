# CScholar Evaluation Survey — System Context and Questionnaire

| Field | Value |
|---|---|
| Document | System context brief + post-implementation evaluation questionnaire |
| Version | 1.0 — 2026-11-25 |
| Purpose | Measure acceptability of CScholar after use, from students, faculty, admin staff, and IT experts |
| Instrument | 5-point Likert scale + feature-use checklist + open-ended items |
| Respondents | Students, faculty, admin, IT experts/panel |
| Related | [`requirements_traceability.md`](../requirements_traceability.md), [`plan_20261120.md`](../plan_20261120.md), [`personalized_recommendations.md`](../personalized_recommendations.md) |

> This file has two jobs. **Part A** is the context your team/panel needs before
> writing or defending the survey. **Parts B–D** are the questionnaire itself,
> the scoring rules, and the administration checklist. Replace the school name
> and population figures before printing.

---

## Fast context for the team (paste-ready)

> CScholar is a web and mobile repository for CEIT thesis and capstone projects.
> Today, students and faculty look for related studies by scrolling through
> shelves, shared folders, or group chats; titles are hard to search because the
> words in a title rarely match the words a student thinks of. CScholar keeps
> the bibliographic record (title, abstract, authors, adviser, program, academic
> year, research type, categories, keywords, PDF) and adds two ways to search:
> normal keyword search with filters, and semantic search that matches meaning
> using 384-dimension sentence embeddings. It also shows related research based
> on similarity, lets students save studies, gives faculty a view of their
> theses and advisees, and gives admins a review workflow (draft → approved →
> published → archived), bulk CSV/PDF import, program/year management, and user
> management. It is built with Flutter (web + mobile, one codebase), FastAPI,
> PostgreSQL with pgvector, and the `all-MiniLM-L6-v2` model. The system is
> scoped to CEIT only.

---

## Part A — System context

### A1. The problem it answers

CEIT produces theses and capstones every year, but the completed studies are
scattered across offices and storage. A student who needs related literature
usually knows the topic, not the exact title. Keyword search fails when the
student's words differ from the title's words, and browsing physically does not
scale. Faculty and admins also need a controlled way to add, review, publish,
and archive entries so that what students see is complete and trustworthy.

### A2. What CScholar does

1. **Stores one record per study** — title, abstract, research type (Thesis or
   Capstone), program, academic year, status, PDF, authors, advisers, categories,
   and keywords.
2. **Finds studies two ways** — keyword search over title/abstract/keywords/author
   names, and semantic search over embedded text chunks, both with filters for
   program, academic year, research type, and category.
3. **Explains related work** — a thesis page lists nearest published studies by
   embedding similarity, labelled as "Related research"/"AI Recommendations"
   with a "Semantic match" badge.
4. **Supports student workflows** — saved studies (kept per account on the
   device), a dashboard, and recommendations anchored on the last study the
   student viewed or saved.
5. **Supports faculty workflows** — My Theses, add/edit entries, My Students
   (advisees), and analytics.
6. **Supports admin workflows** — thesis review and status changes, duplicate
   warnings, bulk import with a preview and error report, program and academic
   year management, and user activation/deactivation.

### A3. Who uses it, and what they can do

| Role | Main screens | What they can do |
|---|---|---|
| **Student** | Repository, thesis detail, saved, dashboard, profile | Search (keyword or semantic), filter, read abstracts, open PDFs, save studies, view recommendations |
| **Faculty** | Faculty dashboard, My Theses, My Students, Analytics, Settings | Everything a student can do, plus create/edit entries and see advisees and their work |
| **Admin** | Admin dashboard, Thesis Management, Bulk Import, Programs, Users, Settings | Everything faculty can do, plus review/publish/archive, bulk import, manage programs and academic years, activate/deactivate accounts |
| **IT expert / panel** | All of the above (walkthrough) | Evaluate the system technically; no production data changes |

### A4. Feature → requirement → survey construct

Use this table when the panel asks why an item exists.

| Feature in CScholar | Requirement | Survey items |
|---|---|---|
| Login, registration, role-based menus | FR-01, FR-02 | FS1, SE1, SE2, TE1, TE2 |
| User activation/deactivation | FR-03 | AD6, TE2 |
| Programs and academic years | FR-04, FR-05 | FS4, AD5, TE4 |
| Create/edit thesis entry | FR-06 | FS1, FC2, TE1 |
| Thesis vs Capstone classification | FR-07 | FS1, FS4 |
| Status lifecycle and review | FR-08 | FC6, AD2, TE4, TE6 |
| PDF storage and viewing | FR-09, FR-10 | FS1, PE3, TE1 |
| Authors, advisers, categories, keywords | FR-11 to FR-14 | FS1, FS4, TE4 |
| Embeddings and semantic search | FR-15, FR-16 | FS2, FS3, PE2, TE3, TE7 |
| Recommendations / related research | FR-17 | FS5, SD2, TE3 |
| Keyword search, filters, search logs | FR-18 | FS2, FS4, US2 |
| Audit fields and review history | FR-19 | AD2, TE4 |
| CEIT-only scope | FR-20 | Profile item, AD5 |

### A5. Limits the questionnaire must respect

Do not write items that promise more than the system does. These are the honest
limits:

- **Corpus size.** The demo corpus is 19 published studies. Questions about
  "comprehensive coverage" would measure the data, not the system. Ask about
  relevance and usefulness instead.
- **Recommendations are content similarity, not a learned profile.** The student
  dashboard is anchored on the last viewed or saved study. Do not ask whether it
  "learns my interests over time."
- **No scholar profiles.** There are no bios, photos, citation counts, or
  h-index. Do not ask respondents to rate them.
- **Saved studies live on the device**, per account — not in a server-side
  library. Ask about convenience, not cross-device sync.
- **Scope is CEIT only**, one college, one active academic year at a time.
- **The API and database schema are frozen.** Evaluation feedback cannot be
  answered with "we will add a table/endpoint" unless the owner approves it.

---

## Part B — Instrument design

### B1. Constructs and item counts

The core items follow ISO/IEC 25010 quality characteristics, translated into
plain language. Role sections measure task fit; the expert section adds the
characteristics end users cannot judge.

| Section | Construct | Items | Who answers |
|---|---|---|---|
| C3 | Functional Suitability (FS) | 5 | Everyone |
| C3 | Usability (US) | 5 | Everyone |
| C3 | Reliability (RE) | 3 | Everyone |
| C3 | Performance Efficiency (PE) | 3 | Everyone |
| C3 | Security (SE) | 3 | Everyone |
| C3 | Portability (PO) | 3 | Everyone |
| C3 | Overall Satisfaction (OV) | 3 | Everyone |
| C4 | Student task fit (SD) | 5 | Students |
| C5 | Faculty task fit (FC) | 6 | Faculty |
| C6 | Admin task fit (AD) | 7 | Admin |
| C7 | Technical quality (TE) | 18 | IT experts |
| C8 | Open-ended | 3 | Everyone |

Burden: students answer 25 core + 5 student + 3 open = **33 items**; faculty 34;
admin 35; IT experts 43. A respondent skips any item marked **N/A** (feature not
used), and that item is excluded from the mean.

### B2. Response scale

Five-point Likert agreement scale. Print the numbers on the form.

| Score | Label | Meaning |
|---|---|---|
| 5 | Strongly Agree | The statement is true every time / without difficulty |
| 4 | Agree | True most of the time |
| 3 | Neutral | Sometimes true, sometimes not / cannot judge |
| 2 | Disagree | Rarely true / difficult |
| 1 | Strongly Disagree | Not true at all / not possible |
| N/A | Not applicable | I did not use this feature |

Interpretation of a computed mean:

| Mean range | Agreement | Acceptability |
|---|---|---|
| 4.21 – 5.00 | Strongly Agree | Highly Acceptable |
| 3.41 – 4.20 | Agree | Acceptable |
| 2.61 – 3.40 | Neutral | Moderately Acceptable |
| 1.81 – 2.60 | Disagree | Not Acceptable |
| 1.00 – 1.80 | Strongly Disagree | Highly Not Acceptable |

Report the mean per construct, not only the grand mean. A system can be
"acceptable" overall while one construct (usually performance or security) is
neutral, and that gap is the useful finding.

### B3. Routing

Use Google Forms **sections with branching** (or four printed versions):

- Q3 = Student → C4, skip C5–C7
- Q3 = Faculty → C5, skip C4, C6–C7
- Q3 = Admin → C6, skip C4–C5, C7
- Q3 = IT expert / panel → C7, skip C4–C6

Everyone answers C0–C3, then their role section, then C8.

### B4. Sampling, validity, and reliability

- **Students.** Use Slovin's formula if the CEIT student population is known:
  `n = N / (1 + N·e²)`, with `e = 0.05`. Example: `N = 600 → n = 240`. Add
  10–20% for incomplete responses. If the population is not documented, use
  purposive sampling and say so — do not invent an N.
- **Faculty and admin.** Total enumeration (ask all of them); the population is
  small.
- **IT experts.** Purposive sample of 5–10, with at least two who did not build
  the system.
- **Content validity.** Give the draft to 3 experts (one CS/IT faculty, one
  research adviser, one end user). Rate each item 1–4 for relevance; keep items
  with an item-level CVI of at least 0.67 (2 of 3 experts) and revise unclear
  wording.
- **Pilot test.** 10–15 respondents outside the final sample. Compute
  Cronbach's alpha per construct; **α ≥ 0.70** is acceptable. Drop or rewrite an
  item that lowers alpha or correlates poorly with its construct.
- **Report the response rate** and any missing/N/A items. Do not silently
  replace missing values with 3.

### B5. Ethics and data handling

- Include the consent paragraph in C0. Participation must be voluntary and
  anonymous.
- Do not collect names, student numbers, or emails on the form. The profile
  section stops at role, program, and year level.
- Store raw responses on a password-protected account, keep them only as long
  as the study needs them, and report only aggregates. This follows RA 10173
  (Data Privacy Act of 2012).
- If the survey is part of a class requirement, clear it with the adviser before
  distributing.

---

## Part C — Questionnaire

### C0. Consent and instructions

> **Purpose.** We are evaluating CScholar, a thesis and capstone repository for
> the College of Engineering and Information Technology. Your answers will help
> us find what works and what needs improvement.
>
> **What you will do.** Use CScholar for at least one search session, then
> answer this form. It takes about 10–15 minutes.
>
> **Privacy.** Do not write your name, student number, or email anywhere on this
> form. Answers are reported only as group totals.
>
> **Voluntary.** You may skip any question or stop at any time.
>
> By continuing, you confirm that you have used CScholar and that you agree to
> take part.

**Instructions.** For each statement, choose the number that matches your
experience: **5 = Strongly Agree, 4 = Agree, 3 = Neutral, 2 = Disagree,
1 = Strongly Disagree, N/A = I did not use this feature.** Answer based on the
session you just finished, not on what you expect the system to become.

### C1. Respondent profile

1. **Role:** ☐ Student ☐ Faculty ☐ Admin staff ☐ IT expert / panel
2. **Program:** ☐ BSIT ☐ BSEE ☐ BSCpE ☐ Not applicable
3. **Year level (students only):** ☐ 1st ☐ 2nd ☐ 3rd ☐ 4th ☐ Graduate
4. **How often did you use CScholar before this evaluation?**
   ☐ First time ☐ Once or twice ☐ Monthly ☐ Weekly ☐ Daily
5. **Device used for this evaluation:**
   ☐ Laptop/desktop browser ☐ Phone browser ☐ Installed phone app ☐ Tablet

### C2. Features used in this session

Tick every feature you actually used. Unticked features should be marked N/A in
the next sections.

☐ Keyword search ☐ Semantic (search by meaning) ☐ Filters (program, year, type,
category) ☐ Thesis detail page ☐ PDF viewing ☐ Saved studies ☐ Recommendations /
related research ☐ Student dashboard ☐ Add/edit thesis (faculty/admin) ☐ My
Students / advisees (faculty) ☐ Analytics (faculty) ☐ Thesis review / status
change (admin) ☐ Bulk import (admin) ☐ Programs / academic years (admin) ☐ User
management (admin) ☐ Dark/light theme ☐ Phone layout

### C3. Core evaluation (all respondents)

#### Functional Suitability

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| FS1 | CScholar gives me the information I need about a study: title, abstract, authors, adviser, category, keywords, and PDF. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| FS2 | The search results are relevant to what I am looking for. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| FS3 | Search by meaning still returns related studies even when my words differ from the title. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| FS4 | The filters (program, academic year, research type, category) narrow the results correctly. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| FS5 | The related research shown on a thesis page is genuinely connected to that thesis. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Usability

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| US1 | I understood how to use CScholar without training or help. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| US2 | I found the search box and filters easily. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| US3 | Moving between the repository, a thesis page, and my saved list was easy. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| US4 | The labels on screen are clear (for example, "semantic search", "AI recommendations", "semantic match"). | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| US5 | When something went wrong, the message told me what to do next. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Reliability

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| RE1 | CScholar loaded and worked without errors during my session. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| RE2 | Repeating the same search gave me the same results. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| RE3 | My saved studies were still there when I came back. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Performance Efficiency

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| PE1 | Pages opened quickly enough for me. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| PE2 | Search results appeared without a long wait. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| PE3 | Opening a PDF did not freeze the app or browser. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Security

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| SE1 | I felt safe entering my account details. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| SE2 | I only saw the pages and records allowed for my role. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| SE3 | My saved studies and account information stayed private. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Portability

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| PO1 | CScholar worked well in the browser. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| PO2 | CScholar worked well on a phone. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| PO3 | The layout adjusted correctly to my screen size. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Overall Satisfaction

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| OV1 | Overall, I am satisfied with CScholar. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| OV2 | CScholar is ready to be used by CEIT this school year. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| OV3 | I would recommend CScholar to other students or faculty. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

### C4. Student section

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| SD1 | The student dashboard shows useful updates and recent studies. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| SD2 | The recommendations helped me discover studies I would not have found by keyword alone. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| SD3 | Saving studies helps me organize references for my own research. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| SD4 | CScholar helps me find related literature for my thesis or capstone. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| SD5 | I would use CScholar instead of manually browsing shelves, folders, or group chats. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

### C5. Faculty section

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| FC1 | My Theses makes it easy to see and manage the studies I handle. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| FC2 | Adding or editing a thesis entry is straightforward. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| FC3 | The duplicate warning helps me avoid submitting a study that already exists. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| FC4 | My Students gives me an accurate view of my advisees. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| FC5 | The analytics page gives me useful information about my advisees' work. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| FC6 | The draft → approved → published → archived workflow matches how our department processes studies. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

### C6. Admin section

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| AD1 | The admin dashboard gives me the overview I need to manage the repository. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| AD2 | Reviewing a thesis and changing its status is easy. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| AD3 | Bulk import saves time compared with adding entries one by one. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| AD4 | The import preview and error report help me fix problems before confirming. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| AD5 | Managing programs and academic years is straightforward. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| AD6 | Activating and deactivating user accounts is easy. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| AD7 | The role permissions match what each person is responsible for. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

### C7. IT expert / panel section

Answer from a technical walkthrough, not from ordinary use. Mark N/A only if you
could not inspect that part.

#### Functional suitability and data integrity

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| TE1 | All documented functions work: login, role access, thesis CRUD, search, recommendations, and import. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE2 | Role-based access is enforced in both the API and the interface. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE3 | Keyword and semantic search return relevant and reproducible results. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE4 | Authors, advisers, categories, keywords, and status transitions are stored and displayed correctly. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Reliability

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| TE5 | Invalid input returns a clear error without crashing the server. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE6 | Database constraints (unique email, status check, foreign keys) prevent invalid records. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Performance

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| TE7 | Search response time is acceptable for the current corpus size. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE8 | Bulk import and embedding generation complete reliably. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Security

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| TE9 | Passwords are hashed, sessions use signed tokens, and secrets are kept out of source code. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE10 | Private fields such as email are hidden from roles that should not see them. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Maintainability and documentation

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| TE11 | The code is separated into routes, services, and models, and is readable. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE12 | The schema is normalized and documented; the ERD and data dictionary match the code. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE13 | Automated tests cover the critical UI flows, and the project builds cleanly. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE14 | The API contract is documented and enforced, so endpoints cannot drift silently. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

#### Compatibility, portability, accessibility

| # | Statement | 5 | 4 | 3 | 2 | 1 | N/A |
|---|---|---|---|---|---|---|---|
| TE15 | One codebase runs on modern browsers and on mobile. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE16 | Configuration (database URL, model, CORS) is externalized and deployment is documented. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE17 | Text contrast, keyboard navigation, and scalable text are adequate. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| TE18 | Error and empty states explain what happened instead of showing a blank screen. | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

### C8. Open-ended

1. What was the most useful part of CScholar for you?
2. What problem did you hit that we should fix first?
3. What one feature or piece of information would you add?

For IT experts only: 4. Which requirement or quality characteristic is weakest,
and why?

### C9. Debrief (optional, interviewer-led)

Ask the respondent to repeat one search out loud and narrate what they expect.
Record where they hesitate. This catches problems the Likert items miss.

---

## Part D — Analysis plan

### D1. Compute the weighted mean

For each item: `mean = (5·n₅ + 4·n₄ + 3·n₃ + 2·n₂ + 1·n₁) / (n₅+n₄+n₃+n₂+n₁)`.
Exclude N/A answers from both the numerator and denominator. Then average the
item means within a construct — do not average raw scores across a construct
with unequal item counts.

```
Functional Suitability = mean(FS1..FS5)
Usability              = mean(US1..US5)
Reliability            = mean(RE1..RE3)
Performance            = mean(PE1..PE3)
Security               = mean(SE1..SE3)
Portability            = mean(PO1..PO3)
Overall                = mean(OV1..OV3)
```

### D2. Report template

| Construct | Items | Mean | SD | Interpretation |
|---|---|---|---|---|
| Functional Suitability | 5 | | | |
| Usability | 5 | | | |
| Reliability | 3 | | | |
| Performance Efficiency | 3 | | | |
| Security | 3 | | | |
| Portability | 3 | | | |
| Overall Satisfaction | 3 | | | |
| **Grand mean** | **25** | | | |

Add one row per role-specific construct (SD, FC, AD, TE) and one column for N
per group. State the interpretation using the table in B2.

### D3. Reliability check

Run Cronbach's alpha per construct on the pilot data (and again on the final
data if the sample allows). Report α and the number of items. If α < 0.70,
inspect the item-total correlations: a negative or near-zero item is usually
ambiguously worded or measures a different construct.

### D4. What to do with low scores

Do not average away a weak construct. For every construct below 3.41, pull the
matching open-ended answers and name the specific screen or step. That is the
finding the panel will ask about, and it is also the only defensible basis for
a recommendation. Remember that the schema and API are frozen: recommend UI,
copy, data, or training fixes first.

### D5. Triangulation

Pair the survey with the existing relevance evaluation
([`relevance_20261120.md`](relevance_20261120.md)) and the demo preflight. The
survey says whether users *perceive* the system as acceptable; the relevance
check says whether keyword vs semantic search actually retrieves the right
studies. Report both, and state the corpus-size limitation openly.

---

## Part E — Administration checklist

- [ ] Adviser approval obtained (if required by the course).
- [ ] Consent paragraph and data-privacy statement on the form.
- [ ] Form branches correctly by role; test it as each role.
- [ ] No name/student-number/email fields anywhere.
- [ ] Pilot with 10–15 respondents; record completion time and confusing items.
- [ ] Three experts reviewed content validity; revisions logged.
- [ ] Students used the system **before** answering (at least one search).
- [ ] Each respondent used only their own account and role.
- [ ] Faculty/admin sessions done on the same build as students.
- [ ] Raw responses stored privately; aggregates only in the paper.
- [ ] Response rate and N/A counts reported.

---

## Appendix A — Optional 10-item usability index (SUS)

Use this only if the panel asks for a standardized usability score. Keep it as a
separate block so it does not mix with the construct means. Alternating items
are reverse-scored (5 becomes 1, and so on).

1. I think that I would like to use CScholar frequently.
2. I found CScholar unnecessarily complex.
3. I thought CScholar was easy to use.
4. I think that I would need the support of a technical person to be able to use CScholar.
5. I found the various functions in CScholar were well integrated.
6. I thought there was too much inconsistency in CScholar.
7. I would imagine that most people would learn to use CScholar very quickly.
8. I found CScholar very cumbersome to use.
9. I felt very confident using CScholar.
10. I needed to learn a lot of things before I could get going with CScholar.

Score: sum the adjusted item scores (reverse items 2, 4, 6, 8, 10), subtract 5,
multiply by 2. Range 0–100; 68 is the usual average, above 80 is excellent.
Report the median and range, not just the mean, for a small sample.

## Appendix B — Form layout

| Form section | Contents | Branch |
|---|---|---|
| 1 | Consent + instructions | All |
| 2 | Profile (C1) + features used (C2) | All |
| 3 | Functional Suitability + Usability | All |
| 4 | Reliability + Performance | All |
| 5 | Security + Portability + Overall | All |
| 6 | Student items (C4) | Student only |
| 6 | Faculty items (C5) | Faculty only |
| 6 | Admin items (C6) | Admin only |
| 6 | Technical items (C7) | IT expert only |
| 7 | Open-ended (C8) | All |
| 8 | Thank-you + debrief note | All |

Keep each section to one screen on mobile. Put the scale legend at the top of
every Likert section, not only the first one.
