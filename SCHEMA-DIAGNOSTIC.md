# NeverNote schema diagnostic — local only

This is an isolated `git archive` of e111174306c7f18fd65247485b9527d7301114f3.
The fixture replaces only the app entry point as application code. Two main-target
macOS signing settings point to a fixture-only copy of the original Mac
entitlements with explicit `Development`. The model file is unchanged.
Do not distribute or upload this diagnostic binary.

## Native check

The app is `DerivedData/Build/Products/Debug/NeverNote.app`.
Root must launch this exact path through normal computer control. It has not
been launched during preparation. The native window is titled
“NeverNote schema diagnostic”; the bundle remains NeverNote's existing ID.

Click **Check account** first. This performs only signature/profile presence,
team/container/development-entitlement validation and CloudKit accountStatus.
Developer/CloudKit Console authentication is separate from OS iCloud login.
If the Mac reports no account, Nathan must sign in through normal system UI.
Do not inspect credentials or switch an existing iCloud account.

Only an available account with explicit signed Development enables
**Initialize development schema**. A separate native confirmation precedes
writes. The helper rechecks signing and account, derives the Core Data model
from the exact original NoteDocument, and calls Apple's initializeCloudKitSchema
with generated representative records in a fresh UUID-named temporary store.
No NevernoteSwiftData path, current notes, old stores or app UserDefaults are
opened. No SwiftData ModelContainer is constructed. Temporary stores are
unloaded when the operation ends. Apple's successful initialization removes
its generated representative records.

## Production follow-up

Verify actual generated record types/fields in the development environment
of iCloud.com.nathanfennel.NeverNote. Do not enter guessed Core Data fields.
In normal CloudKit Console, review **Deploy Schema Changes** and deploy the
reviewed development schema. That step copies schema, not development records.
Then verify the production schema and authenticated behavior using the shipping
TestFlight build. A schema success alone is not proof of cross-device sync.

## Build / signing

Final build succeeded; strict/deep code signature verification passed.
Mac development profile: c09b2591-6e86-4e4b-b904-8d6bce3e30d5.
Signed iCloud environment: Development.
No further automatic provisioning is authorized in this fixture work.
For a purely local rebuild using the now-cached profile:

    xcodebuild -project NeverNote.xcodeproj -scheme NeverNote -configuration Debug -destination 'platform=macOS' -derivedDataPath DerivedData build

See schema-diagnostic-preparation.json for hashes, profile and scope details.
The intermediate global entitlement override unintentionally expanded a widget
profile. Final Watch/widget signed entitlements are restored to original minimal
values. Root must verify its portal capability state; no profiles or capabilities
have been revoked or deleted.

Apple instructions:
- https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
- https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer/initializecloudkitschema(options:)
- https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app
- https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema
