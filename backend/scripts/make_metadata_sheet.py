"""Build a metadata worksheet from converted, searchable thesis PDFs.

Extracts what OCR can be trusted with — title, authors, executive summary or
abstract, research type, program — and leaves a blank for everything only a human
can supply (accession number, academic year, adviser, keywords).

    venv\\Scripts\\python scripts\\make_metadata_sheet.py ..\\..\\pdf --out ..\\..\\metadata.csv

Review every row before importing. OCR misreads names and line breaks.
"""

import argparse
import csv
import glob
import os
import re

import pymupdf

PROGRAM_PHRASES = [
    ("BSCpE", "COMPUTER ENGINEERING"),
    ("BSEE", "ELECTRICAL ENGINEERING"),
    ("BSIT", "INFORMATION TECHNOLOGY"),
]

BOILERPLATE = re.compile(
    r"^(Republic of the Philippines|CARAGA STATE UNIVERSITY(?: CABADBARAN (?:CITY|CAMPUS))?|"
    r"CABADBARAN CITY|COLLEGE OF ENGINEERING.*|T\. Curato.*|\d{3}[\d\s-]*|"
    r".*@.*|URL:.*|www\..*)$",
    re.I,
)

TITLE_MARKER = re.compile(
    r"A\s+(?:CAPSTONE|THESIS)\b|CAPSTONE\s+PROJECT|RESEARCH\s+PAPER", re.I
)

MONTHS = ("January|February|March|April|May|June|July|August|September|"
          "October|November|December")


def clean(text):
    return re.sub(r"\s+", " ", text or "").strip()


def find_abstract(texts):
    """Executive summary (capstones) or abstract (theses), whichever comes first."""
    best = None
    for marker in (r"EXECUTIVE\s+SUMMARY", r"\bABSTRACT\b"):
        for index, text in enumerate(texts[:8]):
            match = re.search(marker, text, re.I)
            if not match:
                continue
            chunk = text[match.end():]
            if len(clean(chunk)) < 400 and index + 1 < len(texts):
                chunk += "\n" + texts[index + 1]
            stop = re.search(r"\b(Keywords?|TABLE OF CONTENTS|CHAPTER\s*1)\b", chunk, re.I)
            if stop:
                chunk = chunk[:stop.start()]
            candidate = clean(chunk)
            if candidate and (best is None or len(candidate) > len(best)):
                best = candidate
    return (best or "")[:3000]


def find_title(texts):
    """Text above the 'A CAPSTONE PROJECT' marker, minus letterhead noise.

    Cutting at the marker's character position (not the line) keeps titles that
    run straight into the marker line, e.g. "...MANAGEMENT INFORMATION SYSTEM
    OFFICE A CAPSTONE PROJECT". Leading institution lines are dropped only when
    they stand alone, so a title that names the university mid-sentence survives.
    """
    text = texts[0]
    match = TITLE_MARKER.search(text)
    before = text[:match.start()] if match else text[:1500]
    lines = [clean(line) for line in before.splitlines()]
    lines = [line for line in lines if line]
    while lines and (BOILERPLATE.match(lines[0]) or re.fullmatch(r"[a-z]{1,4}", lines[0])):
        lines.pop(0)
    return clean(" ".join(lines))


def split_names(raw):
    raw = clean(raw)
    raw = re.sub(r"^(by\s+)", "", raw, flags=re.I)
    # OCR glues initials to surnames: "B.Dionaldo" -> "B. Dionaldo".
    raw = re.sub(r"\b([A-Z])\.(?=[A-Z])", r"\1. ", raw)
    parts = re.split(r",\s*and\s+|,\s*|\s+and\s+", raw)
    names = []
    for part in parts:
        part = clean(part).strip(".,;")
        if not part or len(part.split()) < 2:
            continue
        words = part.replace(",", "").split()
        if len(words) >= 2:
            last = words[-1]
            first = words[0]
            middle = " ".join(words[1:-1])
            names.append(f"{last}, {first}" + (f" {middle}" if middle else ""))
    return "; ".join(names)


def names_from_title_page(text):
    """Fallback for sets without an approval sheet: names under the degree line."""
    lines = [clean(line) for line in text.splitlines() if clean(line)]
    start = None
    for index, line in enumerate(lines):
        if re.search(r"BACHELOR OF SCIENCE IN", line, re.I):
            start = index + 1
    if start is None:
        return ""
    picked = []
    for line in lines[start:]:
        if re.search(rf"^({MONTHS})\s+\d{{4}}$", line, re.I):
            break
        if re.search(r"CAPSTONE|THESIS|COLLEGE|UNIVERSITY|CAMPUS|CITY", line, re.I):
            continue
        if 2 <= len(line.split()) <= 5:
            picked.append(line)
    return split_names(", ".join(picked))


def find_authors(texts):
    joined = clean(" ".join(texts[:4]))
    for pattern in (
        r"submitted\s+by\s+(.+?)\s+(?:in\s+partial|is\s+hereby|in\s+fulfillment)",
        r"prepared\s+and\s+submitted\s+by\s+(.+?)\s+(?:in\s+partial|is\s+hereby)",
    ):
        match = re.search(pattern, joined, re.I)
        if match:
            return split_names(match.group(1))
    return names_from_title_page(texts[0])


def find_program(texts):
    upper = clean(" ".join(texts[:4])).upper()
    for code, phrase in PROGRAM_PHRASES:
        if phrase in upper:
            return code
    return ""


def find_year(texts):
    years = re.findall(r"\b(20\d{2})\b", " ".join(texts[:2]))
    return years[0] if years else ""


def main():
    parser = argparse.ArgumentParser(description="Build a metadata CSV from thesis PDFs.")
    parser.add_argument("folder", help="Folder containing the converted PDFs")
    parser.add_argument("--out", default=None, help="Output CSV path")
    args = parser.parse_args()

    pdfs = sorted(glob.glob(os.path.join(args.folder, "*.pdf")))
    if not pdfs:
        raise SystemExit(f"No PDFs in {args.folder}")

    out_path = args.out or os.path.join(args.folder, "metadata.csv")
    rows = []
    for path in pdfs:
        with pymupdf.open(path) as doc:
            texts = [page.get_text() for page in doc]
            pages = len(doc)
        full = clean(" ".join(texts))
        rows.append({
            "accession_no": "",
            "title": find_title(texts),
            "abstract": find_abstract(texts),
            "research_type": "Capstone" if re.search(r"capstone", full, re.I) else "Thesis",
            "program_code": find_program(texts),
            "academic_year": "",
            "authors": find_authors(texts),
            "adviser": "",
            "keywords": "",
            "categories": "",
            "pdf_filename": os.path.basename(path),
            "pages_scanned": pages,
            "scanned_by": "",
            "notes": f"year on title page: {find_year(texts)}" if find_year(texts) else "",
        })

    with open(out_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    print(f"wrote {out_path} ({len(rows)} rows)")
    for row in rows:
        print(f"\n{row['pdf_filename']}  [{row['research_type']}, {row['program_code'] or '?'}, {row['pages_scanned']}p]")
        print(f"  title   : {row['title'][:90]}")
        print(f"  authors : {row['authors'][:90]}")
        print(f"  summary : {row['abstract'][:90]}...  ({len(row['abstract'])} chars)")


if __name__ == "__main__":
    main()
