"""Compare keyword and semantic retrieval on a small labeled query set.

The set is deliberately mixed: some queries are phrases that appear verbatim in
a title or keyword (keyword should win), others are paraphrases with no shared
words (semantic should win). This is a smoke test for the demo, not a
benchmark: 19 published records is too small for claims beyond "the right study
is usually in the top 3".

Usage (from backend/):
    venv\\Scripts\\python scripts\\eval_relevance.py
"""

import csv
import sys
import time
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))

from app import models as db  # noqa: E402
from app.services.embeddings import embedding_service  # noqa: E402

LIMIT = 3

QUERIES = [
    {"query": "library", "expected": [59], "kind": "verbatim", "note": "keyword phrase in title"},
    {"query": "finding a place to stay near campus", "expected": [58], "kind": "paraphrase", "note": "paraphrase of boarding house"},
    {"query": "detecting cars on the road", "expected": [54], "kind": "paraphrase", "note": "synonym of vehicle detection"},
    {"query": "scholar tracking", "expected": [57], "kind": "verbatim", "note": "keyword phrase in title"},
    {"query": "monitoring electricity of a transformer", "expected": [49], "kind": "paraphrase", "note": "paraphrase of voltage/current monitoring"},
    {"query": "driver's license", "expected": [48], "kind": "verbatim", "note": "keyword term"},
    {"query": "vacation leave", "expected": [51], "kind": "paraphrase", "note": "keyword vocabulary says employee leave"},
    {"query": "incoming and outgoing communication", "expected": [46], "kind": "verbatim", "note": "keyword phrase in title"},
    {"query": "hometel reservation", "expected": [41], "kind": "verbatim", "note": "keyword phrase in title"},
    {"query": "Vistal", "expected": [48, 50, 54, 56], "kind": "person", "note": "adviser surname"},
]


def short(title, width=46):
    text = (title or "").replace("|", "/")
    return text if len(text) <= width else text[: width - 1] + "…"


def keyword_hits(query, limit=LIMIT):
    result = db.list_theses(q=query, status="published", per_page=limit)
    return [row["id"] for row in result["theses"]][:limit]


def main():
    all_rows = db.list_theses(status="published", per_page=100)["theses"]
    titles = {row["id"]: row["title"] for row in all_rows}
    print("published records:", len(all_rows))
    if not embedding_service.available:
        sys.exit("embedding service is not available")

    rows = []
    keyword_times = []
    semantic_times = []
    for item in QUERIES:
        query = item["query"]
        expected = set(item["expected"])

        started = time.perf_counter()
        keyword_ids = keyword_hits(query)
        keyword_times.append((time.perf_counter() - started) * 1000)

        started = time.perf_counter()
        vector = embedding_service.embed(query)
        semantic = db.semantic_search(vector, limit=LIMIT) if vector else []
        semantic_times.append((time.perf_counter() - started) * 1000)

        rows.append(
            {
                "query": query,
                "kind": item["kind"],
                "note": item["note"],
                "expected": sorted(expected),
                "keyword": keyword_ids,
                "semantic": semantic,
            }
        )

    def hit_at(ids, expected):
        return bool(expected.intersection(ids))

    keyword_top1 = sum(hit_at(r["keyword"][:1], set(r["expected"])) for r in rows)
    keyword_top3 = sum(hit_at(r["keyword"], set(r["expected"])) for r in rows)
    semantic_top1 = sum(
        hit_at([x["id"] for x in r["semantic"][:1]], set(r["expected"])) for r in rows
    )
    semantic_top3 = sum(
        hit_at([x["id"] for x in r["semantic"]], set(r["expected"])) for r in rows
    )
    semantic_only = sum(
        hit_at([x["id"] for x in r["semantic"]], set(r["expected"]))
        and not hit_at(r["keyword"], set(r["expected"]))
        for r in rows
    )
    keyword_only = sum(
        hit_at(r["keyword"], set(r["expected"]))
        and not hit_at([x["id"] for x in r["semantic"]], set(r["expected"]))
        for r in rows
    )

    def reciprocal_rank(ids, expected_ids):
        for rank, tid in enumerate(ids, start=1):
            if tid in expected_ids:
                return 1.0 / rank
        return 0.0

    keyword_mrr = sum(
        reciprocal_rank(r["keyword"], set(r["expected"])) for r in rows
    ) / len(rows)
    semantic_mrr = sum(
        reciprocal_rank([x["id"] for x in r["semantic"]], set(r["expected"]))
        for r in rows
    ) / len(rows)

    out_dir = BACKEND.parent / "docs" / "evaluation"
    out_dir.mkdir(parents=True, exist_ok=True)

    md = []
    md.append("# Relevance check — keyword vs semantic")
    md.append("")
    md.append(f"- Date: 2026-11-20")
    md.append(f"- Corpus: {len(all_rows)} published records")
    md.append(f"- Embedding model: `{embedding_service.model_name}`")
    md.append(f"- Cutoff: top {LIMIT}")
    md.append(
        "- Queries were written from the titles on purpose; this is a smoke test, "
        "not a blind benchmark."
    )
    md.append(
        "- Keyword mode matches the query as one contiguous substring, so a "
        "natural-language phrase usually returns nothing unless it appears verbatim."
    )
    md.append("")
    md.append("## Summary")
    md.append("")
    md.append("| Metric | Keyword | Semantic |")
    md.append("|---|---|---|")
    md.append(f"| Hit@1 | {keyword_top1}/{len(rows)} | {semantic_top1}/{len(rows)} |")
    md.append(f"| Hit@3 | {keyword_top3}/{len(rows)} | {semantic_top3}/{len(rows)} |")
    md.append(f"| MRR | {keyword_mrr:.2f} | {semantic_mrr:.2f} |")
    md.append(
        f"| Mean latency | {sum(keyword_times) / len(keyword_times):.0f} ms | "
        f"{sum(semantic_times) / len(semantic_times):.0f} ms |"
    )
    md.append("")
    md.append(f"- Semantic-only wins: **{semantic_only}**")
    md.append(f"- Keyword-only wins: **{keyword_only}**")
    md.append(
        "- Person names are not topics: `Vistal` returns that adviser's theses in "
        "keyword mode, while semantic ranking surfaces only the one whose content "
        "happens to be nearest."
    )
    md.append(
        "- `Vistal` expects any of that adviser's four theses, so hit@3 means "
        "'at least one of the four'."
    )
    md.append("")
    md.append("## Per query")
    md.append("")
    md.append("**Bold** marks the expected record.")
    md.append("")
    md.append("| # | Query | Type | Expected | Keyword top-3 | Semantic top-3 |")
    md.append("|---|---|---|---|---|---|")

    csv_rows = []
    for index, row in enumerate(rows, start=1):
        expected = set(row["expected"])
        keyword = ", ".join(
            f"**{tid}**" if tid in expected else str(tid) for tid in row["keyword"]
        ) or "—"
        semantic = ", ".join(
            (f"**{x['id']}**" if x["id"] in expected else str(x["id"]))
            + f" {short(titles.get(x['id'], ''), 30)} "
            + f"({x['similarity'] * 100:.0f}%)"
            for x in row["semantic"]
        ) or "—"
        md.append(
            f"| {index} | {row['query']} | {row['kind']} "
            f"| {', '.join(map(str, row['expected']))} "
            f"| {keyword} | {semantic} |"
        )

        for rank, tid in enumerate(row["keyword"], start=1):
            csv_rows.append(
                [row["query"], "keyword", rank, tid, titles.get(tid, ""), "", int(tid in expected)]
            )
        for rank, hit in enumerate(row["semantic"], start=1):
            csv_rows.append(
                [
                    row["query"],
                    "semantic",
                    rank,
                    hit["id"],
                    titles.get(hit["id"], ""),
                    f"{hit['similarity']:.4f}",
                    int(hit["id"] in expected),
                ]
            )

    md.append("")
    md.append("## Record ids")
    md.append("")
    md.append("| Id | Title |")
    md.append("|---|---|")
    for tid in sorted(titles):
        md.append(f"| {tid} | {short(titles[tid], 110)} |")

    (out_dir / "relevance_20261120.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    with (out_dir / "relevance_20261120.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(["query", "mode", "rank", "thesis_id", "title", "similarity", "is_expected"])
        writer.writerows(csv_rows)

    print(
        f"keyword hit@1 {keyword_top1}/{len(rows)} hit@3 {keyword_top3}/{len(rows)} | "
        f"semantic hit@1 {semantic_top1}/{len(rows)} hit@3 {semantic_top3}/{len(rows)}"
    )
    print(f"semantic-only wins: {semantic_only} | keyword-only wins: {keyword_only}")
    print("wrote:", out_dir / "relevance_20261120.md")
    print("wrote:", out_dir / "relevance_20261120.csv")


if __name__ == "__main__":
    main()
