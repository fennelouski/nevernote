---
name: build
description: Build the Nevernote iOS app for the iOS Simulator. Use when the user types /build or asks to build for simulator, verify a simulator build, or check whether the app compiles.
---

# Build For Simulator

## Goal

Produce a simulator build for this repository and report clear pass/fail output.

## Workflow

1. Confirm workspace root is the repository.
2. Determine an available simulator destination:
   - Prefer: `platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.4.1`
   - Fallback: `platform=iOS Simulator,name=iPhone 17 Pro Max`
   - Final fallback: `generic/platform=iOS Simulator`
3. Build with `xcodebuild` using this command shape:

```bash
xcodebuild \
  -project Nevernote.xcodeproj \
  -scheme NeverNote \
  -configuration Debug \
  -destination "<resolved destination>" \
  -sdk iphonesimulator \
  build
```

4. If destination lookup fails, retry once using `-destination "generic/platform=iOS Simulator"`.
5. If build fails, report:
   - failing command
   - first meaningful error(s)
   - smallest next fix to unblock build
6. If build succeeds, report success and destination used.

### watchOS (optional)

To verify the embedded watch app and widget extension:

```bash
xcodebuild \
  -project Nevernote.xcodeproj \
  -scheme NeverNote \
  -configuration Debug \
  -destination 'generic/platform=watchOS Simulator' \
  -sdk watchsimulator \
  build
```

If `actool` fails with a watch simulator runtime vs SDK mismatch, install the matching **watchOS Simulator** runtime in Xcode (Settings → Platforms) or add a Watch App Icon in the **NeverNote Watch App** target via Xcode (Asset Catalog), which generates metadata compatible with your SDK.

## Output Format

- `Result`: success or failure
- `Destination`: simulator destination used
- `Command`: exact build command run
- `Notes`: key warnings/errors and next step if needed

## Guardrails

- Do not modify project settings unless the user asks.
- Do not run destructive git commands.
- Keep logs concise; include only actionable build errors in chat.

## Active development focus

- **Primary app code** lives under `NeverNote/` (SwiftUI). Prefer building and changing that tree.
- **`NeverNote1/`** is legacy UIKit/Objective-C; avoid edits there unless the user explicitly asks or a build must be unblocked. See `.cursor/rules/active-development-stack.mdc`.
