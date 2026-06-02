#!/usr/bin/env python3
"""
Audit NeverNote String Catalog localization quality.

Checks:
  - key parity per locale vs source (en)
  - missing / extra keys
  - placeholder integrity (%@, %d, positional, \\n, %%)
  - values still identical to English (optional --intentional-ok)

Usage:
  python3 scripts/localization-audit.py
  python3 scripts/localization-audit.py --catalog NeverNote/Localizable.xcstrings
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

PLACEHOLDER_RE = re.compile(r"%(?:\d+\$)?[@dDuUxXfFeEgGcCsSpaA%]|\\n")

# Values that may legitimately match English across locales.
INTENTIONAL_IDENTICAL = frozenset(
    {
        "16:9",
        "9:16",
        "OK",
        "Nevernote",
        "NeverNote",
        "NEVERNOTE FOCUS",
    }
)

ENGLISH_VARIANT_PREFIXES = ("en",)


def load_catalog(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def placeholders(value: str) -> list[str]:
    return PLACEHOLDER_RE.findall(value)


def catalog_entries(catalog: dict) -> dict[str, dict[str, str]]:
    """key -> locale -> value"""
    out: dict[str, dict[str, str]] = {}
    for key, entry in catalog.get("strings", {}).items():
        locs: dict[str, str] = {}
        for locale, loc_entry in entry.get("localizations", {}).items():
            value = loc_entry.get("stringUnit", {}).get("value")
            if value is not None:
                locs[locale] = value
        if locs:
            out[key] = locs
    return out


def is_english_variant(locale: str) -> bool:
    return locale == "en" or locale.startswith("en-")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--catalog",
        type=Path,
        default=Path("NeverNote/Localizable.xcstrings"),
        help="Path to .xcstrings catalog",
    )
    parser.add_argument(
        "--source",
        default="en",
        help="Source locale (default: en)",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    catalog_path = args.catalog if args.catalog.is_absolute() else root / args.catalog

    if not catalog_path.is_file():
        print(f"ERROR: catalog not found: {catalog_path}", file=sys.stderr)
        return 1

    catalog = load_catalog(catalog_path)
    entries = catalog_entries(catalog)
    source = args.source

    all_locales: set[str] = set()
    for locs in entries.values():
        all_locales.update(locs.keys())

    if source not in all_locales:
        print(f"ERROR: source locale {source!r} not in catalog", file=sys.stderr)
        return 1

    source_keys = set(entries)
    failures = 0

    print(f"Catalog: {catalog_path}")
    print(f"Keys: {len(source_keys)}")
    print(f"Locales: {len(all_locales)}")
    print()

    print("Per-locale key parity:")
    print(f"{'locale':<12} {'keys':>6} {'missing':>8} {'extra':>6} {'ph_fail':>8} {'en_copy':>8}")
    print("-" * 56)

    placeholder_failures: list[tuple[str, str, list[str], list[str]]] = []
    identical_counts: dict[str, int] = {}

    for locale in sorted(all_locales):
        if locale == source:
            continue
        locale_keys = {k for k, locs in entries.items() if locale in locs}
        missing = source_keys - locale_keys
        extra = locale_keys - source_keys
        ph_fail = 0
        en_copy = 0

        for key in source_keys & locale_keys:
            en_val = entries[key].get(source, "")
            loc_val = entries[key].get(locale, "")
            if placeholders(en_val) != placeholders(loc_val):
                ph_fail += 1
                placeholder_failures.append(
                    (locale, key, placeholders(en_val), placeholders(loc_val))
                )
            if (
                loc_val == en_val
                and en_val not in INTENTIONAL_IDENTICAL
                and not is_english_variant(locale)
            ):
                en_copy += 1

        if missing or extra or ph_fail:
            failures += 1
        identical_counts[locale] = en_copy
        print(
            f"{locale:<12} {len(locale_keys):>6} {len(missing):>8} {len(extra):>6} "
            f"{ph_fail:>8} {en_copy:>8}"
        )

    print()
    fully_identical = [
        loc
        for loc in sorted(all_locales)
        if loc != source
        and not is_english_variant(loc)
        and identical_counts.get(loc, 0)
        == len([k for k in source_keys if loc in entries.get(k, {})])
    ]
    # Recompute fully identical properly
    fully_identical = []
    for locale in sorted(all_locales):
        if locale == source or is_english_variant(locale):
            continue
        keys_with = [k for k in source_keys if locale in entries.get(k, {})]
        if not keys_with:
            continue
        same = sum(
            1
            for k in keys_with
            if entries[k].get(locale) == entries[k].get(source)
        )
        if same == len(keys_with):
            fully_identical.append(locale)

    print(f"Fully identical to {source} (non-en-*): {fully_identical or 'none'}")
    print(f"Placeholder mismatches: {len(placeholder_failures)}")
    if placeholder_failures[:5]:
        for loc, key, en_ph, loc_ph in placeholder_failures[:5]:
            print(f"  {loc} / {key}: en={en_ph} loc={loc_ph}")

    print()
    if failures or placeholder_failures:
        print("RESULT: FAIL (key parity or placeholders)")
        return 1
    print("RESULT: PASS (key parity + placeholders)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
