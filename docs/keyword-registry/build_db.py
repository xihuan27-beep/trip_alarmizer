#!/usr/bin/env python3
"""
Builds content.sqlite from the markdown registry (keywords-table-a.md,
site-links-table-c.md, sources-table-d.md) plus Sources/Resources/sites.json.

Usage: python3 build_db.py
Regenerates docs/keyword-registry/content.sqlite from scratch every run.
"""
import json
import re
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SITES_JSON = ROOT.parent.parent / "Sources" / "Resources" / "sites.json"
DB_PATH = ROOT / "content.sqlite"

TYPES = {"인물", "장소", "사건·날짜", "사물·유물", "개념·제도", "전설모티프"}


def clean_cell(cell: str) -> str:
    cell = cell.strip()
    cell = cell.replace("`", "")
    return cell.strip()


def parse_pipe_table_rows(lines, start_idx):
    """Given lines and the index of a header row '| a | b | ... |',
    returns (rows, next_idx) where rows is a list of cell-lists,
    skipping the separator row. Stops at first non-table line."""
    header = [clean_cell(c) for c in lines[start_idx].strip().strip("|").split("|")]
    i = start_idx + 1
    if i >= len(lines) or not re.match(r"^\s*\|(\s*:?-+:?\s*\|)+\s*$", lines[i]):
        return header, [], i
    i += 1
    rows = []
    while i < len(lines) and lines[i].strip().startswith("|"):
        raw = lines[i].strip().strip("|")
        cells = [clean_cell(c) for c in raw.split("|")]
        rows.append(cells)
        i += 1
    return header, rows, i


def find_all_tables(text):
    """Yields (header, rows) for every pipe-table found in the text."""
    lines = text.splitlines()
    i = 0
    tables = []
    while i < len(lines):
        if lines[i].strip().startswith("|") and lines[i].count("|") >= 2:
            header, rows, next_i = parse_pipe_table_rows(lines, i)
            if rows or header:
                tables.append((header, rows))
            i = next_i
        else:
            i += 1
    return tables


def strip_annotation(text: str) -> str:
    """Removes trailing italic annotations like '*(비고: ... 통합됨)*' or
    '*(확장 후보 ...)*' from a cell, returning the clean value."""
    text = re.sub(r"\s*\*\(.*?\)\*\s*$", "", text).strip()
    return text


CLAIM_TAG_MAP = {
    "전설": ("legend", None),
    "논쟁": (None, "disputed"),
    "대체됨": (None, "superseded"),
}


def strip_claim_tag(claim: str) -> tuple[str, str, str]:
    """Parses an optional leading '[전설|논쟁|대체됨]' tag off a Table D claim
    cell. Returns (clean_claim, claim_type, status), defaulting to
    ('historical', 'preferred') when no tag is present. See README.md
    "충돌·전설 표기" for the convention and when to use which tag."""
    claim_type, status = "historical", "preferred"
    m = re.match(r"^\[(전설|논쟁|대체됨)\]\s*", claim)
    if m:
        ct, st = CLAIM_TAG_MAP[m.group(1)]
        claim_type = ct or claim_type
        status = st or status
        claim = claim[m.end():].strip()
    return claim, claim_type, status


TYPE_PREFIX_MAP = [
    ("인물", "인물"),
    ("장소", "장소"),
    ("사건", "사건·날짜"),
    ("사물", "사물·유물"),
    ("개념", "개념·제도"),
    ("전설", "전설모티프"),
]


def normalize_type(raw_type: str) -> str:
    """Maps a free-form type string (e.g. '전설모티프(지명)', '개념(학술논쟁)',
    '사건·개념') down to one of the 6 canonical categories in README.md."""
    for prefix, canonical in TYPE_PREFIX_MAP:
        if raw_type.startswith(prefix):
            return canonical
    return raw_type  # unrecognized — surfaced by the CHECK constraint at insert time


# ---------------------------------------------------------------------------
# Table A: keywords-table-a.md
# ---------------------------------------------------------------------------
def load_keywords():
    text = (ROOT / "keywords-table-a.md").read_text(encoding="utf-8")
    tables = find_all_tables(text)
    keywords = {}
    for header, rows in tables:
        if len(header) != 5 or header[0] != "keyword_id":
            continue
        for r in rows:
            if len(r) != 5:
                continue
            kid, ko, th, en, typ = r
            if not kid or kid.startswith("keyword_id"):
                continue
            # Skip cross-reference placeholder rows, e.g. "(위 ... 섹션 참고)"
            if ko.startswith("(") and ko.endswith(")"):
                continue
            ko_clean = strip_annotation(ko)
            typ_clean = strip_annotation(typ)
            is_orphan = "확장 후보" in typ or "확장 후보" in ko
            if kid in keywords:
                # Keep the richer (first-seen) definition; just note re-occurrence.
                continue
            keywords[kid] = {
                "keyword_id": kid,
                "ko": ko_clean,
                "th": th,
                "en": en,
                "type": normalize_type(typ_clean),
                "type_detail": typ_clean,
                "is_orphan": 1 if is_orphan else 0,
            }
    return keywords


# ---------------------------------------------------------------------------
# Table C: site-links-table-c.md
# ---------------------------------------------------------------------------
def load_site_links():
    text = (ROOT / "site-links-table-c.md").read_text(encoding="utf-8")
    tables = find_all_tables(text)
    links = []
    for header, rows in tables:
        if len(header) != 3 or header[0] != "keyword_id":
            continue
        for r in rows:
            if len(r) != 3:
                continue
            kid, sid, relation = r
            if not kid or kid.startswith("keyword_id"):
                continue
            if sid.startswith("(") or not sid:
                continue
            links.append({"keyword_id": kid, "site_id": sid, "relation": relation})
    return links


# ---------------------------------------------------------------------------
# Table D: sources-table-d.md  (mixed 2-col / 3-col sections; some sections
# share one fixed source cited in prose right before the table)
# ---------------------------------------------------------------------------
def load_sources():
    text = (ROOT / "sources-table-d.md").read_text(encoding="utf-8")
    lines = text.splitlines()
    sources = []
    i = 0
    pending_shared_source = None
    while i < len(lines):
        line = lines[i]
        # A "출처:" line right before a table supplies a shared source for
        # tables whose header is only (keyword_id | 주장 내용).
        m = re.search(r"출처[:：]\s*`([^`]+)`", line)
        if m:
            pending_shared_source = m.group(1).strip()
        if line.strip().startswith("|") and line.count("|") >= 2:
            header, rows, next_i = parse_pipe_table_rows(lines, i)
            if header and header[0] == "keyword_id":
                if len(header) == 3:
                    for r in rows:
                        if len(r) != 3:
                            continue
                        kid, src, claim = r
                        if not kid or kid.startswith("keyword_id"):
                            continue
                        claim, claim_type, status = strip_claim_tag(claim)
                        sources.append({"keyword_id": kid, "source": src, "claim": claim,
                                         "claim_type": claim_type, "status": status})
                elif len(header) == 2:
                    for r in rows:
                        if len(r) != 2:
                            continue
                        kid, claim = r
                        if not kid or kid.startswith("keyword_id"):
                            continue
                        src = pending_shared_source or "(출처 미상 — 원문 확인 필요)"
                        claim, claim_type, status = strip_claim_tag(claim)
                        sources.append({"keyword_id": kid, "source": src, "claim": claim,
                                         "claim_type": claim_type, "status": status})
            i = next_i
        else:
            i += 1
    return sources


# ---------------------------------------------------------------------------
# Table B: Sources/Resources/sites.json
# ---------------------------------------------------------------------------
def load_sites():
    data = json.loads(SITES_JSON.read_text(encoding="utf-8"))
    return data


def main():
    keywords = load_keywords()
    links = load_site_links()
    sources = load_sources()
    sites = load_sites()

    print(f"Parsed: {len(keywords)} keywords, {len(links)} site-links, "
          f"{len(sources)} source-claims, {len(sites)} sites")

    site_ids = {s["id"] for s in sites}

    # --- Integrity checks -------------------------------------------------
    errors = []
    for l in links:
        if l["keyword_id"] not in keywords:
            errors.append(f"site-link references unknown keyword_id: {l['keyword_id']} -> {l['site_id']}")
        if l["site_id"] not in site_ids:
            errors.append(f"site-link references unknown site_id: {l['site_id']} (keyword {l['keyword_id']})")
    for s in sources:
        if s["keyword_id"] not in keywords:
            errors.append(f"source references unknown keyword_id: {s['keyword_id']}")
    linked_keyword_ids = {l["keyword_id"] for l in links}
    orphans_without_flag = [
        k for k, v in keywords.items()
        if k not in linked_keyword_ids and not v["is_orphan"]
    ]

    if errors:
        print(f"\n❌ {len(errors)} integrity error(s):")
        for e in errors[:50]:
            print("  -", e)
        sys.exit(1)

    if orphans_without_flag:
        print(f"\n⚠️  {len(orphans_without_flag)} keyword(s) have no site-link and "
              f"aren't marked as 확장 후보 (orphan candidate) in the markdown — "
              f"flagged as orphan in the DB anyway:")
        for k in orphans_without_flag:
            print("  -", k)
            keywords[k]["is_orphan"] = 1

    # --- Build the database -------------------------------------------------
    if DB_PATH.exists():
        DB_PATH.unlink()
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    cur = conn.cursor()

    cur.executescript("""
    CREATE TABLE sites (
        site_id        TEXT PRIMARY KEY,
        name            TEXT NOT NULL,
        name_thai       TEXT,
        latitude        REAL,
        longitude       REAL,
        radius_meters   INTEGER,
        category        TEXT,
        year_built      TEXT,
        teaser          TEXT,
        story           TEXT
    );

    CREATE TABLE keywords (
        keyword_id  TEXT PRIMARY KEY,
        ko          TEXT NOT NULL,
        th          TEXT NOT NULL,
        en          TEXT NOT NULL,
        type        TEXT NOT NULL CHECK (type IN
            ('인물','장소','사건·날짜','사물·유물','개념·제도','전설모티프')),
        type_detail TEXT NOT NULL,
        is_orphan   INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE site_links (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        keyword_id  TEXT NOT NULL REFERENCES keywords(keyword_id),
        site_id     TEXT NOT NULL REFERENCES sites(site_id),
        relation    TEXT NOT NULL,
        UNIQUE(keyword_id, site_id, relation)
    );

    CREATE TABLE sources (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        keyword_id  TEXT NOT NULL REFERENCES keywords(keyword_id),
        source      TEXT NOT NULL,
        claim       TEXT NOT NULL,
        claim_type  TEXT NOT NULL DEFAULT 'historical'
            CHECK (claim_type IN ('historical','legend','disputed')),
        status      TEXT NOT NULL DEFAULT 'preferred'
            CHECK (status IN ('preferred','disputed','superseded'))
    );

    CREATE INDEX idx_site_links_keyword ON site_links(keyword_id);
    CREATE INDEX idx_site_links_site    ON site_links(site_id);
    CREATE INDEX idx_sources_keyword    ON sources(keyword_id);
    """)

    for s in sites:
        cur.execute(
            "INSERT INTO sites (site_id, name, name_thai, latitude, longitude, "
            "radius_meters, category, year_built, teaser, story) "
            "VALUES (?,?,?,?,?,?,?,?,?,?)",
            (s["id"], s.get("name"), s.get("nameThai"), s.get("latitude"),
             s.get("longitude"), s.get("radiusMeters"), s.get("category"),
             s.get("yearBuilt"), s.get("teaser"), s.get("story")),
        )

    for k in keywords.values():
        cur.execute(
            "INSERT INTO keywords (keyword_id, ko, th, en, type, type_detail, is_orphan) "
            "VALUES (?,?,?,?,?,?,?)",
            (k["keyword_id"], k["ko"], k["th"], k["en"], k["type"], k["type_detail"], k["is_orphan"]),
        )

    for l in links:
        cur.execute(
            "INSERT OR IGNORE INTO site_links (keyword_id, site_id, relation) "
            "VALUES (?,?,?)",
            (l["keyword_id"], l["site_id"], l["relation"]),
        )

    for s in sources:
        cur.execute(
            "INSERT INTO sources (keyword_id, source, claim, claim_type, status) VALUES (?,?,?,?,?)",
            (s["keyword_id"], s["source"], s["claim"], s["claim_type"], s["status"]),
        )

    conn.commit()

    # --- Sanity: conflict-detection query works -----------------------------
    cur.execute("""
        SELECT keyword_id, COUNT(*) c FROM sources
        GROUP BY keyword_id HAVING c > 1 ORDER BY c DESC
    """)
    multi = cur.fetchall()
    print(f"\n{len(multi)} keyword(s) have 2+ independent source rows "
          f"(conflict-detection candidates), top 5:")
    for kid, c in multi[:5]:
        print(f"  - {kid}: {c} sources")

    cur.execute("SELECT keyword_id, source FROM sources WHERE status='disputed' ORDER BY keyword_id")
    disputed = cur.fetchall()
    cur.execute("SELECT keyword_id, source FROM sources WHERE status='superseded' ORDER BY keyword_id")
    superseded = cur.fetchall()
    cur.execute("SELECT keyword_id, source FROM sources WHERE claim_type='legend' ORDER BY keyword_id")
    legend = cur.fetchall()
    print(f"\nclaim_type/status tags: {len(disputed)} disputed row(s), "
          f"{len(superseded)} superseded row(s), {len(legend)} legend row(s).")

    conn.close()
    print(f"\n✅ Wrote {DB_PATH}")


if __name__ == "__main__":
    main()
