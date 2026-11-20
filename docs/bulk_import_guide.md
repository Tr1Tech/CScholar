# Bulk Import — staff guide

For library staff and admins adding a batch of theses/capstones **without using
the terminal**.

> The screen requires the **admin** role. There is no separate librarian role
> yet; give library staff an admin account until RBAC adds one.

## What you need

1. A **spreadsheet** with one row per study.
2. One **PDF** per study, named exactly as the `pdf_filename` in the spreadsheet.

The admin screen can download the spreadsheet template for you.

## Step by step

1. Sign in as an **admin**.
2. Open **Theses / Capstone**, then click **Bulk Import** (next to **Add Thesis**). The dashboard's **Quick Management → Bulk Import** shortcut opens the same screen.
3. Click **Download CSV template**.
4. Fill it in Excel or Google Sheets. Keep the header row unchanged.
   - **Delete the example row.** It is there only to show the format; the
     importer rejects it so it can never become a record.
   - `accession_no` may be blank.
   - `authors` use `Last, First M.`, separated by semicolons:
     `Dela Cruz, Juan P.; Santos, Maria L.`
   - `keywords` and `categories` are separated by semicolons.
   - `pdf_filename` must match the PDF file name exactly, for example
     `CEIT_BSIT_2023_0142.pdf`.
   - Do not leave `title`, `abstract`, `research_type`, `program_code`,
     `academic_year`, `authors`, or `pdf_filename` empty.
5. Save the spreadsheet as **CSV (comma separated)**.
6. In Bulk Import, choose the CSV, then choose **all** PDFs for that batch.
7. Click **Check batch**.
8. Review the preview. Nothing has been saved yet.
   - **Ready** — a new draft will be created.
   - **Already imported** — the study is already in the repository; it will be skipped.
   - **Will update** — the study exists but is missing its PDF or search index; the import will repair it.
   - **Error** — fix the CSV (or the missing PDF) and upload again.
9. If there are no errors, click **Import … studies as drafts**.
10. Leave the page open while it runs. Indexing happens in the background.
11. Download the **report** when it finishes.

## After the import

Imported studies are **drafts**. They are not visible to students until they
are reviewed and published.

1. Click **Review drafts**.
2. Select the studies with the checkboxes.
3. Click **Approve selected**.
4. Select the approved studies (the screen switches the filter for you) and
   click **Publish selected**.

Only an **approved** study can be published. If a row is skipped, its status
was not the expected one — the message in the snackbar explains why.

## Linking an adviser to a faculty account

Imported advisers have **no email** on purpose — the importer does not invent
addresses. Until an adviser is linked, that faculty member's **My Theses**,
**My Students**, **Analytics**, and dashboard show nothing.

1. Open **Programs & Tags → Advisers**.
2. Find the adviser and click the edit (pencil) button.
3. Enter the adviser's **CSU email — the same email they use to sign in**.
4. Save. The row changes from **NO ACCOUNT** to **LINKED**, and their faculty
   pages fill in on the next load.

Clearing the email unlinks the adviser again.

## What the importer does for you

- Creates programs? No — the program code must already exist (`BSIT`, `BSEE`,
  `BSCpE`). An unknown code is reported as an error.
- Creates academic years when the label is valid and missing.
- Creates authors, advisers, categories, and keywords when they do not exist.
- Copies each PDF into the repository's upload folder.
- Builds the text chunks and semantic-search vectors automatically.
- Downloads an import report with one line per row.

You do **not** do anything AI-related. The semantic index is built the same way
it is when you save a single study through the admin form.

## Rules and limits

- **Admin only.** Faculty and students cannot open the screen or the API.
- **One batch at a time.** A second import waits until the first finishes.
- CSV maximum **5 MB**; each PDF maximum **50 MB**; at most **100 PDFs** per batch.
- PDFs with no text layer are OCR'd automatically if Tesseract is installed.
  Without Tesseract they are still imported and indexed on title + abstract.
- Re-running the same CSV is safe: existing records are skipped, not duplicated.

## Common errors

| Message | What to do |
|---|---|
| `unknown program_code` | Use one of the existing codes, or ask an admin to add the program. |
| `PDF not found` | The `pdf_filename` does not match an uploaded file. Check spelling and upload the missing PDF. |
| `duplicate of row N` | Two rows in the CSV describe the same study. Remove one. |
| `title+year already exists ... different first author` | A record with that title/year exists with another first author. Check for a typo or a true duplicate. |
| `expected 'Last, First M.'` | The author cell is not in `Last, First M.` form. |
| `academic_year ... is not a YYYY-YYYY label` | Use e.g. `2023-2024` with consecutive years. |
| `this is the template's example row` | Delete the sample row (or replace its title) and upload again. |
| `PDF has no usable text layer` | Warning only. Install Tesseract for full-text indexing, or accept title+abstract search. |

## Where things live

- Screen: `/admin/import`, reached from **Theses / Capstone → Bulk Import**
- API: `/api/import/*` (admin only)
- CLI fallback: `backend/scripts/import_theses.py` (same validation/import code)
- Reports: downloaded from the result screen, or `import_report.csv` from the CLI
