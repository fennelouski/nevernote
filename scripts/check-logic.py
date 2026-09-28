#!/usr/bin/env python3
"""Run the existing model/formatting tests without launching the application."""
import pathlib
import shutil
import subprocess
import tempfile
repo = pathlib.Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='nevernote-logic-') as temp:
    root = pathlib.Path(temp)
    source = root / 'Sources/NeverNote'
    tests = root / 'Tests/NeverNoteTests'
    source.mkdir(parents=True)
    tests.mkdir(parents=True)
    (root / 'Package.swift').write_text('''// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "NeverNoteChecks", platforms: [.macOS("15.0")], targets: [.target(name: "NeverNote"), .testTarget(name: "NeverNoteTests", dependencies: ["NeverNote"])])
''')
    for name in ['NoteRichTextCodec', 'NoteTranslationEligibility', 'NoteHTTPPasteboardLinkFormatting', 'NoteLanguageDetection', 'NoteLocaleFlagEmoji']:
        shutil.copy(repo / ('NeverNote/' + name + '.swift'), source)
    for name in ['NoteLogicTests.swift', 'NoteLocaleFlagEmojiTests.swift']:
        shutil.copy(repo / 'NeverNoteTests' / name, tests)
    subprocess.run(['swift', 'test', '--package-path', str(root)], check=True)
