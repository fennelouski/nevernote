#!/usr/bin/env python3
"""
Generate NeverNote/Localizable.xcstrings for every iOS / App Store locale.

Usage:
  python3 scripts/build-localizable-xcstrings.py              # English + manual overrides
  python3 scripts/build-localizable-xcstrings.py --translate  # Fill all locales via Google Translate
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

# Every language Apple lists for App Store metadata + common Xcode regional variants.
# https://developer.apple.com/help/app-store-connect/reference/app-store-localizations
IOS_ALL_LOCALES = [
    "en",
    "en-US",
    "en-GB",
    "en-AU",
    "en-CA",
    "en-IN",
    "ar",
    "bn",
    "ca",
    "zh-Hans",
    "zh-Hant",
    "zh-HK",
    "hr",
    "cs",
    "da",
    "nl",
    "fi",
    "fr",
    "fr-CA",
    "de",
    "el",
    "gu",
    "he",
    "hi",
    "hu",
    "id",
    "it",
    "ja",
    "kn",
    "ko",
    "ml",
    "mr",
    "ms",
    "nb",
    "no",
    "or",
    "pa",
    "pl",
    "pt-BR",
    "pt-PT",
    "ro",
    "ru",
    "sk",
    "sl",
    "es",
    "es-ES",
    "es-MX",
    "es-419",
    "sv",
    "ta",
    "te",
    "th",
    "tr",
    "uk",
    "ur",
    "vi",
]

# Map Xcode locale identifiers to deep-translator / Google language codes.
LOCALE_TO_TRANSLATOR: dict[str, str | None] = {
    "en": None,
    "en-US": None,
    "en-GB": None,
    "en-AU": None,
    "en-CA": None,
    "en-IN": None,
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
    "zh-HK": "zh-TW",
    "nb": "no",
    "no": "no",
    "es-ES": "es",
    "es-MX": "es",
    "es-419": "es",
    "es": "es",
    "fr-CA": "fr",
    "fr": "fr",
    "pt-BR": "pt",
    "pt-PT": "pt",
    "he": "iw",  # Google Translate legacy Hebrew code
    "or": "or",
}

STRINGS: dict[str, str] = {
    "Add Photo": "Add Photo",
    "Camera": "Camera",
    "Photo Library": "Photo Library",
    "Cancel": "Cancel",
    "Help and support": "Help and support",
    "Nevernote": "Nevernote",
    "Smart links": "Smart links",
    "View captured image": "View captured image",
    "Import text from photo": "Import text from photo",
    "Undo delete": "Undo delete",
    "Delete note": "Delete note",
    "Share note": "Share note",
    "Bold": "Bold",
    "Italic": "Italic",
    "Underline": "Underline",
    "Font": "Font",
    "Alignment": "Alignment",
    "Maximize presentation size": "Maximize presentation size",
    "Line markers": "Line markers",
    "Plain lines": "Plain lines",
    "Bulleted list": "Bulleted list",
    "Numbered list": "Numbered list",
    "Toggle line markers": "Toggle line markers",
    "Align left": "Align left",
    "Align center": "Align center",
    "Align right": "Align right",
    "Hide keyboard": "Hide keyboard",
    "More formatting": "More formatting",
    "Enter text before dismissing the keyboard": "Enter text before dismissing the keyboard",
    "Done": "Done",
    "LAST EDITED %@.": "LAST EDITED %@.",
    "NEVERNOTE FOCUS": "NEVERNOTE FOCUS",
    "Checking image…": "Checking image…",
    "Image link": "Image link",
    "Show this image below the note?": "Show this image below the note?",
    "Hide image at bottom": "Hide image at bottom",
    "Show image at bottom": "Show image at bottom",
    "Can't use this link as an image": "Can't use this link as an image",
    "OK": "OK",
    "Size": "Size",
    "Recent": "Recent",
    "All Fonts": "All Fonts",
    "Search fonts": "Search fonts",
    "Reset": "Reset",
    "System Bold": "System Bold",
    "Share your note?": "Share your note?",
    "You just took a screenshot. Share the note text, or create a clean image of your text only.": (
        "You just took a screenshot. Share the note text, or create a clean image of your text only."
    ),
    "Share note text": "Share note text",
    "Share as image of text": "Share as image of text",
    "Aspect ratio": "Aspect ratio",
    "The image will contain only your text and background — no buttons or frames.": (
        "The image will contain only your text and background — no buttons or frames."
    ),
    "Import Text from a Photo": "Import Text from a Photo",
    "Take a photo or choose one from your library. NeverNote will read any text in the image and add it to your note.": (
        "Take a photo or choose one from your library. NeverNote will read any text in the image and add it to your note."
    ),
    "Continue": "Continue",
    "Not Now": "Not Now",
    "Portrait": "Portrait",
    "9:16": "9:16",
    "Square": "Square",
    "16:9": "16:9",
    "Landscape": "Landscape",
    "Could not load that link.": "Could not load that link.",
    "Image is too large.": "Image is too large.",
    "That link is not an image.": "That link is not an image.",
    "Open Nevernote to read or capture a note.": "Open Nevernote to read or capture a note.",
    "Add text": "Add text",
    "Dictate or type": "Dictate or type",
    "Add": "Add",
    "Save": "Save",
    "screenshot.demo.0": "Open.\nType.\nDone",
    "screenshot.demo.1": "Perfect for catching a quick number during a call.",
    "screenshot.demo.2": "Just a clean space for your immediate thoughts.",
    "screenshot.demo.3": "No folders.\nNo tags.\nNo distractions.",
    "screenshot.demo.4": "The fastest way to capture a fleeting thought.",
}

INFOPLIST_STRINGS: dict[str, str] = {
    "NSCameraUsageDescription": (
        "NeverNote uses the camera to photograph text and import it into your note."
    ),
    "NSPhotoLibraryUsageDescription": (
        "NeverNote accesses your photo library to import text from a photo into your note."
    ),
}


def translator_code(locale: str) -> str | None:
    if locale in LOCALE_TO_TRANSLATOR:
        return LOCALE_TO_TRANSLATOR[locale]
    if locale.startswith("en"):
        return None
    return locale


def unit(value: str, state: str = "translated") -> dict:
    return {"stringUnit": {"state": state, "value": value}}


def translate_text(translator, text: str) -> str:
    if "\n" in text:
        parts = text.split("\n")
        return "\n".join(
            translator.translate(part) if part.strip() else part for part in parts
        )
    return translator.translate(text)


def build_translation_cache(translate: bool) -> dict[tuple[str, str], str]:
    """(locale, english_text) -> translated text."""
    if not translate:
        return {}

    try:
        from deep_translator import GoogleTranslator
    except ImportError:
        print("Install deep-translator: pip3 install deep-translator", file=sys.stderr)
        sys.exit(1)

    cache: dict[tuple[str, str], str] = {}
    unique_en = sorted(set(STRINGS.values()) | set(INFOPLIST_STRINGS.values()))

    # English variants
    for locale in IOS_ALL_LOCALES:
        if translator_code(locale) is None:
            for text in unique_en:
                cache[(locale, text)] = text

    # One pass per distinct target language code
    codes_to_locales: dict[str, list[str]] = {}
    for locale in IOS_ALL_LOCALES:
        code = translator_code(locale)
        if code is None:
            continue
        codes_to_locales.setdefault(code, []).append(locale)

    for code, locales in sorted(codes_to_locales.items()):
        print(f"Translating language {code} -> {', '.join(locales)} …", flush=True)
        try:
            translator = GoogleTranslator(source="en", target=code)
        except Exception as exc:
            print(f"  skip {code}: {exc}", flush=True)
            for locale in locales:
                for text in unique_en:
                    cache[(locale, text)] = text
            continue

        per_code: dict[str, str] = {}
        for text in unique_en:
            try:
                per_code[text] = translate_text(translator, text)
                time.sleep(0.06)
            except Exception as exc:
                print(f"  warn: {code} failed for {text[:50]!r}: {exc}", flush=True)
                per_code[text] = text

        for locale in locales:
            for text in unique_en:
                cache[(locale, text)] = per_code[text]
        time.sleep(0.15)

    return cache


def localized_value(
    locale: str,
    en_value: str,
    cache: dict[tuple[str, str], str],
    translate: bool,
) -> tuple[str, str]:
    if locale == "en" or not translate:
        if locale.startswith("en") or locale == "en":
            return en_value, "translated"
        if (locale, en_value) in cache:
            return cache[(locale, en_value)], "translated"
        return en_value, "needs_review"

    value = cache.get((locale, en_value), en_value)
    state = "translated" if value != en_value or locale.startswith("en") else "translated"
    return value, state


def build_localizable(cache: dict[tuple[str, str], str], translate: bool) -> dict:
    strings: dict = {}
    for key, en_value in STRINGS.items():
        locs = {}
        for locale in IOS_ALL_LOCALES:
            value, state = localized_value(locale, en_value, cache, translate)
            locs[locale] = unit(value, state)
        strings[key] = {"comment": key, "localizations": locs}
    return {
        "sourceLanguage": "en",
        "strings": strings,
        "version": "1.0",
    }


def build_infoplist(cache: dict[tuple[str, str], str], translate: bool) -> dict:
    strings: dict = {}
    for key, en_value in INFOPLIST_STRINGS.items():
        locs = {}
        for locale in IOS_ALL_LOCALES:
            value, state = localized_value(locale, en_value, cache, translate)
            locs[locale] = unit(value, state)
        strings[key] = {"comment": f"Privacy - {key}", "localizations": locs}
    return {
        "sourceLanguage": "en",
        "strings": strings,
        "version": "1.0",
    }


def write_known_regions_snippet() -> None:
    lines = ["\t\t\tknownRegions = ("]
    lines.append("\t\t\t\tEnglish,")
    lines.append("\t\t\t\tBase,")
    for loc in IOS_ALL_LOCALES:
        if loc in ("en",):
            lines.append("\t\t\t\ten,")
        else:
            lines.append(f'\t\t\t\t"{loc}",')
    lines.append("\t\t\t);")
    snippet_path = Path(__file__).resolve().parent / "ios-known-regions.txt"
    snippet_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {snippet_path} (paste into project.pbxproj if needed)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--translate",
        action="store_true",
        help="Machine-translate every string into every locale (requires deep-translator + network)",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    cache = build_translation_cache(args.translate)

    loc_path = root / "NeverNote" / "Localizable.xcstrings"
    loc_path.write_text(
        json.dumps(build_localizable(cache, args.translate), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    plist_path = root / "NeverNote" / "InfoPlist.xcstrings"
    existing = json.loads(plist_path.read_text(encoding="utf-8"))
    generated = build_infoplist(cache, args.translate)
    # Preserve auto-extracted bundle name keys if present
    for preserved in ("CFBundleDisplayName", "CFBundleName"):
        if preserved in existing.get("strings", {}):
            generated["strings"][preserved] = existing["strings"][preserved]
    plist_path.write_text(
        json.dumps(generated, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    write_known_regions_snippet()
    print(
        f"Wrote {loc_path.name} + InfoPlist.xcstrings "
        f"({len(STRINGS)} UI keys, {len(INFOPLIST_STRINGS)} plist keys, {len(IOS_ALL_LOCALES)} locales)"
    )


if __name__ == "__main__":
    main()
