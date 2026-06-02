#!/usr/bin/env python3
"""
Fill NeverNote/Localizable.xcstrings locales that still copy English values.

- Adds regional / App Store locales missing from the catalog (cloned from parent + MT).
- Translates per-key English copies for non-English locales (skips intentional matches).
- English regional variants (en-*) copy en intentionally.

Requires: .venv-localize with deep-translator (or pip install deep-translator)

Usage:
  .venv-localize/bin/python scripts/fix-identical-localizations.py
  .venv-localize/bin/python scripts/fix-identical-localizations.py --dry-run
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from copy import deepcopy
from pathlib import Path

# Locales from localization QA pass (regional + language coverage).
TARGET_LOCALES = [
    "af", "am", "az", "be", "bg", "bn", "bs", "ca", "cs", "da",
    "de-AT", "de-CH", "el", "en-AU", "en-CA", "en-GB", "en-IN", "en-NZ", "en-SG",
    "en-US", "en", "es-419", "es-MX", "es-US", "et", "eu", "fa", "fi", "fil",
    "fr-BE", "fr-CH", "gl", "gu", "hi-Latn", "hr", "hu", "hy", "id", "is", "it-CH",
    "ka", "kk", "km", "kn", "lo", "lt", "lv", "mk", "ml", "mn", "mr", "ms", "my",
    "nb", "ne", "nl-BE", "nn", "no", "pa", "ro", "si", "sk", "sl", "sq", "sr",
    "sw", "ta", "te", "th", "tl", "ug", "ur", "uz", "yue-CN", "zh-CN", "zh-HK",
    "zh-Hant", "zh-TW", "zh", "zu",
]

INTENTIONAL_IDENTICAL = frozenset(
    {"16:9", "9:16", "OK", "Nevernote", "NeverNote", "NEVERNOTE FOCUS"}
)

# New locale -> existing catalog locale to seed before machine translation.
LOCALE_PARENT: dict[str, str] = {
    "de-AT": "de",
    "de-CH": "de",
    "en-AU": "en",
    "en-CA": "en",
    "en-GB": "en",
    "en-IN": "en",
    "en-NZ": "en",
    "en-SG": "en",
    "en-US": "en",
    "es-419": "es",
    "es-MX": "es",
    "es-US": "es",
    "fr-BE": "fr",
    "fr-CH": "fr",
    "it-CH": "it",
    "nl-BE": "nl",
    "zh-CN": "zh-Hans",
    "zh-TW": "zh-Hant",
    "zh-HK": "zh-Hant",
    "zh": "zh-Hans",
    "no": "nb",
    "nn": "nb",
    "fil": "id",
    "tl": "id",
}

# (locale, english value) -> corrected translation (high-confidence UI fixes).
MANUAL_FIXES: dict[tuple[str, str], str] = {
    ("nb", "Font"): "Skrift",
    ("nb", "Format"): "Formatering",
    ("nb", "Note"): "Notat",
    ("nb", "Smart link"): "Smartlenke",
    ("ro", "Font"): "Font",
    ("ro", "Font…"): "Font…",
    ("ro", "Format"): "Formatare",
    ("ro", "Recent"): "Recente",
    ("ca", "Font"): "Font",
    ("ca", "Font…"): "Font…",
    ("ca", "Format"): "Format",
    ("ca", "Recent"): "Recents",
    ("nl", "Camera"): "Camera",
    ("nl", "Open"): "Openen",
    ("nl", "Recent"): "Recent",
    ("it", "Font"): "Carattere",
    ("it", "Font…"): "Carattere…",
    ("it", "Reset"): "Reimposta",
    ("hr", "Font"): "Font",
    ("hr", "Font…"): "Font…",
    ("hr", "Format"): "Formatiranje",
    ("fr", "Format"): "Mise en forme",
    ("fr", "Note"): "Note",
    ("fr", "Portrait"): "Portrait",
    ("da", "Format"): "Formatering",
    ("da", "Note"): "Note",
    ("da", "Smart link"): "Smart-link",
    ("is", "Bulleted List"): "Punktalisti",
    ("is", "Smart Links"): "Snjalltenglar",
    ("sv", "Font"): "Teckensnitt",
    ("sv", "Font…"): "Teckensnitt…",
    ("et", "Font"): "Font",
    ("et", "Font…"): "Font…",
    ("ms", "Format"): "Format",
    ("ms", "Italic"): "Huruf condong",
    ("lv", "Plain Lines"): "Vienkāršas rindas",
    ("lv", "System Bold"): "Sistēmas treknraksts",
    ("hu", "Reset"): "Visszaállítás",
    ("hu", "System Bold"): "Rendszer félkövér",
    (
        "eu",
        "Can't use this link as an image",
    ): "Ezin da esteka hau irudi gisa erabili",
}

LOCALE_TO_TRANSLATOR: dict[str, str | None] = {
    "en": None,
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
    "zh-CN": "zh-CN",
    "zh-TW": "zh-TW",
    "zh-HK": "zh-TW",
    "zh": "zh-CN",
    "yue-CN": "zh-TW",
    "pt-BR": "pt",
    "pt-PT": "pt",
    "nb": "no",
    "no": "no",
    "nn": "no",
    "he": "iw",
    "fil": "tl",
    "tl": "tl",
    "hi-Latn": "hi",
}


def translator_code(locale: str) -> str | None:
    if locale in LOCALE_TO_TRANSLATOR:
        return LOCALE_TO_TRANSLATOR[locale]
    if locale.startswith("en"):
        return None
    base = locale.split("-")[0]
    if base in LOCALE_TO_TRANSLATOR:
        return LOCALE_TO_TRANSLATOR[base]
    return base


def is_english_variant(locale: str) -> bool:
    return locale == "en" or locale.startswith("en-")


def unit(value: str, state: str = "translated") -> dict:
    return {"stringUnit": {"state": state, "value": value}}


def translate_text(translator, text: str) -> str:
    if "\n" in text:
        parts = text.split("\n")
        return "\n".join(
            translator.translate(part) if part.strip() else part for part in parts
        )
    return translator.translate(text)


def get_value(entry: dict, locale: str) -> str | None:
    return (
        entry.get("localizations", {})
        .get(locale, {})
        .get("stringUnit", {})
        .get("value")
    )


def set_value(entry: dict, locale: str, value: str, state: str = "translated") -> None:
    entry.setdefault("localizations", {})[locale] = unit(value, state)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report planned work only (no network, no file writes)",
    )
    parser.add_argument(
        "--catalog",
        type=Path,
        default=Path("NeverNote/Localizable.xcstrings"),
    )
    parser.add_argument(
        "--infoplist",
        type=Path,
        default=Path("NeverNote/InfoPlist.xcstrings"),
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    loc_path = args.catalog if args.catalog.is_absolute() else root / args.catalog
    plist_path = args.infoplist if args.infoplist.is_absolute() else root / args.infoplist

    for path in (loc_path, plist_path):
        if not path.is_file():
            print(f"ERROR: missing {path}", file=sys.stderr)
            return 1

    loc_data = json.loads(loc_path.read_text(encoding="utf-8"))
    plist_data = json.loads(plist_path.read_text(encoding="utf-8"))
    loc_orig = deepcopy(loc_data)
    plist_orig = deepcopy(plist_data)

    source = loc_data.get("sourceLanguage", "en")
    strings = loc_data["strings"]

    present: set[str] = set()
    for entry in strings.values():
        present.update(entry.get("localizations", {}))

    to_add = [loc for loc in TARGET_LOCALES if loc not in present]
    print(f"Adding {len(to_add)} new locales to Localizable: {', '.join(to_add) or 'none'}")

    # Seed new locales from parent or en.
    for loc in to_add:
        parent = LOCALE_PARENT.get(loc, source)
        for key, entry in strings.items():
            en_val = get_value(entry, source)
            if en_val is None:
                continue
            if is_english_variant(loc):
                set_value(entry, loc, en_val)
                continue
            parent_val = get_value(entry, parent) if parent in present else None
            set_value(entry, loc, parent_val if parent_val else en_val)

    # Collect texts needing translation per language code.
    need_mt: dict[str, set[str]] = {}  # translator_code -> english texts

    def queue_mt(locale: str, en_text: str) -> None:
        if en_text in INTENTIONAL_IDENTICAL:
            return
        if is_english_variant(locale):
            return
        code = translator_code(locale)
        if code is None:
            return
        need_mt.setdefault(code, set()).add(en_text)

    for loc in to_add:
        if is_english_variant(loc):
            continue
        for key, entry in strings.items():
            en_val = get_value(entry, source)
            loc_val = get_value(entry, loc)
            if en_val and loc_val == en_val:
                queue_mt(loc, en_val)

    for key, entry in strings.items():
        en_val = get_value(entry, source)
        if en_val is None:
            continue
        for locale in list(entry.get("localizations", {})):
            if locale == source or is_english_variant(locale):
                continue
            loc_val = get_value(entry, locale)
            if loc_val == en_val and en_val not in INTENTIONAL_IDENTICAL:
                queue_mt(locale, en_val)

    print(f"Machine-translating {len(need_mt)} language codes …")
    mt_cache: dict[tuple[str, str], str] = {}  # (code, en) -> translated

    if args.dry_run:
        for code, texts in sorted(need_mt.items()):
            print(f"  would translate {code}: {len(texts)} strings")
        print("Dry run — no files written.")
        return 0

    try:
        from deep_translator import GoogleTranslator
    except ImportError:
        print("Install deep-translator in .venv-localize", file=sys.stderr)
        return 1

    for code in sorted(need_mt):
        texts = sorted(need_mt[code])
        print(f"  {code}: {len(texts)} unique strings", flush=True)
        try:
            translator = GoogleTranslator(source="en", target=code)
        except Exception as exc:
            print(f"    skip {code}: {exc}", flush=True)
            continue
        for text in texts:
            try:
                mt_cache[(code, text)] = translate_text(translator, text)
                time.sleep(0.04)
            except Exception as exc:
                print(f"    warn {code} {text[:40]!r}: {exc}", flush=True)
                mt_cache[(code, text)] = text
        time.sleep(0.08)

    changed_loc = 0
    for key, entry in strings.items():
        en_val = get_value(entry, source)
        if en_val is None:
            continue
        for locale in TARGET_LOCALES:
            if locale not in entry.get("localizations", {}):
                continue
            if is_english_variant(locale):
                continue
            loc_val = get_value(entry, locale)
            if loc_val != en_val or en_val in INTENTIONAL_IDENTICAL:
                continue
            manual = MANUAL_FIXES.get((locale, en_val))
            if manual:
                set_value(entry, locale, manual)
                changed_loc += 1
                continue
            code = translator_code(locale)
            if code is None:
                continue
            new_val = mt_cache.get((code, en_val), loc_val)
            if new_val != loc_val:
                set_value(entry, locale, new_val)
                changed_loc += 1

    print(f"Updated {changed_loc} locale-string cells in Localizable.xcstrings")

    # Mirror new locales + English-copy fixes into InfoPlist for parity.
    plist_strings = plist_data["strings"]
    plist_changed = 0
    for pentry in plist_strings.values():
        en_val = get_value(pentry, source)
        if en_val is None:
            continue
        for loc in to_add:
            if is_english_variant(loc):
                set_value(pentry, loc, en_val)
            else:
                parent = LOCALE_PARENT.get(loc)
                val = (
                    get_value(pentry, parent)
                    if parent and parent in pentry.get("localizations", {})
                    else None
                )
                if not val or val == en_val:
                    code = translator_code(loc)
                    val = mt_cache.get((code, en_val), en_val) if code else en_val
                set_value(pentry, loc, val)
            plist_changed += 1
        for loc in TARGET_LOCALES:
            if loc not in pentry.get("localizations", {}) or is_english_variant(loc):
                continue
            loc_val = get_value(pentry, loc)
            if loc_val == en_val and en_val not in INTENTIONAL_IDENTICAL:
                code = translator_code(loc)
                nv = mt_cache.get((code, en_val)) if code else None
                if nv and nv != loc_val:
                    set_value(pentry, loc, nv)
                    plist_changed += 1

    print(f"InfoPlist cells touched: {plist_changed}")

    loc_path.write_text(
        json.dumps(loc_data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    plist_path.write_text(
        json.dumps(plist_data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    # Snippet for Xcode knownRegions
    all_locales = sorted(
        {loc for e in strings.values() for loc in e.get("localizations", {})}
    )
    snippet = root / "scripts" / "ios-known-regions.txt"
    lines = ["\t\t\tknownRegions = (", "\t\t\t\tEnglish,", "\t\t\t\tBase,"]
    for loc in all_locales:
        if loc == "en":
            lines.append("\t\t\t\ten,")
        else:
            lines.append(f'\t\t\t\t"{loc}",')
    lines.append("\t\t\t);")
    snippet.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {snippet}")

    if loc_data == loc_orig and plist_data == plist_orig:
        print("No changes made.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
