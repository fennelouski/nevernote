#!/usr/bin/env python3
"""Fill remaining English-copy strings in Nevernote String Catalogs."""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

# Import shared helpers from fix-identical-localizations.py (hyphenated module name).
import importlib.util

_fix_path = Path(__file__).resolve().parent / "fix-identical-localizations.py"
_spec = importlib.util.spec_from_file_location("fix_identical_localizations", _fix_path)
_fix = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_fix)

INTENTIONAL_IDENTICAL = _fix.INTENTIONAL_IDENTICAL
LOCALE_PARENT = _fix.LOCALE_PARENT
MANUAL_FIXES = _fix.MANUAL_FIXES
get_value = _fix.get_value
is_english_variant = _fix.is_english_variant
set_value = _fix.set_value
translate_text = _fix.translate_text
translator_code = _fix.translator_code

PLACEHOLDER_RE = re.compile(r"%(?:\d+\$)?[@dDuUxXfFeEgGcCsSpaA%]|%%")

# Extra high-confidence fixes where MT often returns English cognates.
EXTRA_MANUAL: dict[tuple[str, str], str] = {
    ("de", "Format"): "Formatierung",
    ("de-AT", "Format"): "Formatierung",
    ("de-CH", "Format"): "Formatierung",
    ("pl", "Format"): "Formatowanie",
    ("id", "Format"): "Format",
    ("ms", "Format"): "Format",
    ("az", "Format"): "Formatlaşdırma",
    ("uz", "Format"): "Formatlash",
    ("fil", "Format"): "Format",
    ("tl", "Format"): "Format",
    ("da", "Note"): "Note",
    ("fi", "Plain Lines"): "Yksinkertaiset rivit",
    ("fr", "Format"): "Mise en forme",
    ("fr", "Note"): "Note",
    ("fr", "Portrait"): "Portrait",
    ("fr-BE", "Format"): "Mise en forme",
    ("fr-BE", "Note"): "Note",
    ("fr-BE", "Portrait"): "Portrait",
    ("fr-CH", "Format"): "Mise en forme",
    ("fr-CH", "Note"): "Note",
    ("fr-CH", "Portrait"): "Portrait",
    ("ca", "Font"): "Tipus de lletra",
    ("ca", "Font…"): "Tipus de lletra…",
    ("ca", "Format"): "Format",
    ("it", "Font"): "Carattere",
    ("it", "Font…"): "Carattere…",
    ("it", "Reset"): "Reimposta",
    ("it-CH", "Font"): "Carattere",
    ("it-CH", "Font…"): "Carattere…",
    ("it-CH", "Reset"): "Reimposta",
    ("nl", "Camera"): "Camera",
    ("nl", "Open"): "Openen",
    ("nl", "Recent"): "Recent",
    ("nl-BE", "Camera"): "Camera",
    ("nl-BE", "Open"): "Openen",
    ("nl-BE", "Recent"): "Recent",
    ("no", "Font"): "Skrift",
    ("no", "Format"): "Formatering",
    ("no", "Note"): "Notat",
    ("no", "Smart link"): "Smartlenke",
    ("nn", "Font"): "Skrift",
    ("nn", "Format"): "Formatering",
    ("nn", "Note"): "Notat",
    ("nn", "Smart link"): "Smartlenke",
    ("ro", "Font"): "Caractere",
    ("ro", "Font…"): "Caractere…",
    ("sv", "Font"): "Teckensnitt",
    ("sv", "Font…"): "Teckensnitt…",
    ("hr", "Font"): "Font",
    ("hr", "Font…"): "Font…",
    ("hr", "Format"): "Formatiranje",
    ("et", "Font"): "Kiri",
    ("et", "Font…"): "Kiri…",
    ("sq", "Align Center"): "Qendërzo",
    ("bs", "Align Center"): "Poravnaj po sredini",
    ("bs", "Bold"): "Podebljano",
    ("bs", "Bulleted List"): "Lista s oznakama",
    ("bs", "Feature Flags"): "Značajke zastavica",
    ("bs", "Font"): "Font teksta",
    ("bs", "Font…"): "Font teksta…",
    ("bs", "Format"): "Formatiranje",
    ("bs", "Photo Library"): "Biblioteka fotografija",
    ("bs", "Plain Lines"): "Običajni redovi",
    ("bs", "Reset"): "Poništi",
    ("bs", "Screenshot Share"): "Dijeljenje snimka ekrana",
    ("bs", "Share Note"): "Podijeli bilješku",
    ("bs", "Smart Links"): "Pametne veze",
    ("bs", "Smart link"): "Pametna veza",
    ("bs", "Square"): "Kvadrat",
    ("bs", "System Bold"): "Sistemsko podebljano",
    ("ug", "Align Center"): "ئوتتۇرىغا توغرىلاش",
    ("ug", "Bold"): "توم",
    ("ug", "Font…"): "خەت نۇسخىسى…",
    ("ug", "LAST EDITED %@."): "ئاخىرقى تەھرىر %@.",
    ("ug", "Portrait"): "تىك",
    ("ug", "Smart Links"): "ئەقلىي ئۇلانمىلار",
    ("ug", "System Bold"): "سىستېما توم",
    ("gu", "Maximize Presentation Size"): "પ્રસ્તુતિનું કદ મહત્તમ કરો",
    ("hy", "Screenshot Share"): "Էկրանի պատկերի կիսում",
    ("kn", "Screenshot Share"): "ಸ್ಕ್ರೀನ್‌ಶಾಟ್ ಹಂಚಿಕೆ",
    ("si", "Screenshot Share"): "තිර රූපය බෙදාගැනීම",
    ("ml", "Show image at bottom"): "ചിത്രം താഴെ കാണിക്കുക",
    ("my", "System Bold"): "စနစ် ထူထူ",
    ("yue-CN", "screenshot.demo.2"): "一個乾淨空間，記低你即刻嘅諗法。",
}

# Prefer nb for Norwegian variants when nb is already translated.
NORWEGIAN_FALLBACK_PARENT = "nb"


def all_manual(locale: str, en: str) -> str | None:
    return EXTRA_MANUAL.get((locale, en)) or MANUAL_FIXES.get((locale, en))


def preserve_placeholders(en: str, translated: str) -> str:
    en_ph = PLACEHOLDER_RE.findall(en)
    if not en_ph:
        return translated
    loc_ph = PLACEHOLDER_RE.findall(translated)
    if en_ph == loc_ph:
        return translated
    # Rebuild: keep translation text but restore English placeholder tokens in order.
    result = translated
    for ph in en_ph:
        if ph not in result:
            # Insert before trailing punctuation if possible
            result = result.replace("  ", " ", 1)
            if ph == "%@." and "%@." not in result:
                if "%@" in result:
                    result = result.replace("%@", "%@.", 1)
                else:
                    result = f"{result.rstrip()} {ph}".strip()
            elif ph not in result:
                result = f"{result} {ph}".strip()
    loc_ph2 = PLACEHOLDER_RE.findall(result)
    if en_ph != loc_ph2:
        # Last resort: use en structure with translated prefix (for simple one-placeholder strings)
        if len(en_ph) == 1 and en.count(en_ph[0]) == 1:
            prefix = translated.split(en_ph[0])[0].strip() or translated
            if en_ph[0] in en:
                return en.replace(en.split(en_ph[0])[0], prefix + " ", 1) if prefix else en
    return result


def find_gaps(catalog: dict, source: str = "en") -> list[tuple[str, str, str]]:
    """(locale, key, en_value) needing translation."""
    gaps: list[tuple[str, str, str]] = []
    for key, entry in catalog["strings"].items():
        en = get_value(entry, source)
        if en is None:
            continue
        for locale in entry.get("localizations", {}):
            if locale == source or is_english_variant(locale):
                continue
            lv = get_value(entry, locale)
            if lv == en and en not in INTENTIONAL_IDENTICAL:
                gaps.append((locale, key, en))
    return gaps


def parent_value(catalog: dict, key: str, locale: str, source: str) -> str | None:
    entry = catalog["strings"][key]
    en = get_value(entry, source)
    parent = LOCALE_PARENT.get(locale)
    if locale in ("no", "nn"):
        parent = NORWEGIAN_FALLBACK_PARENT
    if not parent:
        return None
    pv = get_value(entry, parent)
    if pv and en and pv != en:
        return pv
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    loc_path = root / "Nevernote" / "Localizable.xcstrings"
    plist_path = root / "Nevernote" / "InfoPlist.xcstrings"
    source = "en"

    loc_data = json.loads(loc_path.read_text(encoding="utf-8"))
    plist_data = json.loads(plist_path.read_text(encoding="utf-8"))

    gaps = find_gaps(loc_data, source)
    print(f"Localizable gaps: {len(gaps)}")

    # Phase 1: manual + parent
    fixed = 0
    still: list[tuple[str, str, str]] = []
    for locale, key, en in gaps:
        entry = loc_data["strings"][key]
        manual = all_manual(locale, en)
        if manual:
            set_value(entry, locale, manual)
            fixed += 1
            continue
        pv = parent_value(loc_data, key, locale, source)
        if pv:
            set_value(entry, locale, pv)
            fixed += 1
            continue
        still.append((locale, key, en))

    print(f"Fixed via manual/parent: {fixed}")
    print(f"Remaining for MT: {len(still)}")

    if args.dry_run:
        from collections import Counter

        c = Counter(loc for loc, _, _ in still)
        for loc, n in c.most_common(15):
            print(f"  {loc}: {n}")
        return 0

    try:
        from deep_translator import GoogleTranslator
    except ImportError:
        print("Need deep-translator (.venv-localize)", file=sys.stderr)
        return 1

    # Phase 2: per-locale MT for remainder
    by_locale: dict[str, set[str]] = {}
    for locale, _, en in still:
        by_locale.setdefault(locale, set()).add(en)

    mt_fixed = 0
    for locale in sorted(by_locale):
        code = translator_code(locale)
        if not code:
            continue
        texts = sorted(by_locale[locale])
        print(f"  MT {locale} ({code}): {len(texts)} strings", flush=True)
        try:
            translator = GoogleTranslator(source="en", target=code)
        except Exception as exc:
            print(f"    skip: {exc}", flush=True)
            continue
        cache: dict[str, str] = {}
        for text in texts:
            try:
                tr = translate_text(translator, text)
                cache[text] = preserve_placeholders(text, tr)
                time.sleep(0.05)
            except Exception as exc:
                print(f"    warn {text[:40]!r}: {exc}", flush=True)
                cache[text] = text

        for locale2, key, en in still:
            if locale2 != locale:
                continue
            tr = cache.get(en, en)
            if tr != en:
                set_value(loc_data["strings"][key], locale2, tr)
                mt_fixed += 1

    print(f"Fixed via MT: {mt_fixed}")

    # InfoPlist: copy privacy strings from parent or MT for locales still English
    for pkey, pentry in plist_data["strings"].items():
        en = get_value(pentry, source)
        if not en:
            continue
        for locale in list(pentry.get("localizations", {})):
            if is_english_variant(locale):
                continue
            lv = get_value(pentry, locale)
            if lv != en:
                continue
            parent = LOCALE_PARENT.get(locale)
            if locale in ("no", "nn"):
                parent = NORWEGIAN_FALLBACK_PARENT
            pv = get_value(pentry, parent) if parent else None
            if pv and pv != en:
                set_value(pentry, locale, pv)
                continue
            code = translator_code(locale)
            if code:
                try:
                    tr = GoogleTranslator(source="en", target=code).translate(en)
                    set_value(pentry, locale, tr)
                    time.sleep(0.05)
                except Exception:
                    pass

    loc_path.write_text(
        json.dumps(loc_data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    plist_path.write_text(
        json.dumps(plist_data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    # Final gap count
    remaining = find_gaps(loc_data, source)
    print(f"Remaining Localizable gaps: {len(remaining)}")
    if remaining:
        from collections import Counter

        for loc, n in Counter(x[0] for x in remaining).most_common(10):
            print(f"  {loc}: {n}")
    return 0 if not remaining else 0


if __name__ == "__main__":
    raise SystemExit(main())
