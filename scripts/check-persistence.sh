#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
check_dir=$(mktemp -d "${TMPDIR:-/tmp}/nevernote-checks.XXXXXX")
trap 'rm -rf "$check_dir"' EXIT
# Compile the exact released model with the same module name as the migration reader.
git show ed9f63e6e6a1a572a2bde1aa8178a9c3a6aaf17e:Nevernote/Item.swift > "$check_dir/LegacyItem.swift"
xcrun swiftc -parse-as-library -module-name NeverNoteStorageChecks -D LEGACY_FIXTURE "$check_dir/LegacyItem.swift" NeverNote/NoteRichTextCodec.swift scripts/check-persistence.swift -o "$check_dir/seed"
xcrun swiftc -parse-as-library -module-name NeverNoteStorageChecks NeverNote/Item.swift NeverNote/NoteRichTextCodec.swift NeverNote/NeverNoteCloudKit.swift NeverNote/NevernoteModelContainer.swift scripts/check-persistence.swift -o "$check_dir/check"
"$check_dir/seed" "$check_dir/stores"
"$check_dir/check" "$check_dir/stores"
