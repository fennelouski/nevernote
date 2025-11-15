# NeverNote iOS Modernization - Remaining Tasks

## Summary
This document tracks remaining tasks to fully modernize the NeverNote iOS application for iOS 17+ while maintaining backward compatibility with iOS 12+.

## Completed Tasks ✅
- Updated deployment target from iOS 7.1 to iOS 12.0
- Replaced deprecated UILaunchImages with LaunchScreen.storyboard
- Updated deprecated calendar unit constants (NSCalendarUnit*)
- Updated status bar APIs to use animated versions
- Added basic safe area support for devices with notches
- Updated Core Data initialization with automatic migration options
- Replaced deprecated UIBarButtonItemStyleBordered with UIBarButtonItemStylePlain
- Updated Xcode project settings for modern toolchain

---

## High Priority Tasks

### 1. Dynamic Screen Size Support
**Priority**: Critical
**Affected Files**: All view controllers
**Description**: The app currently uses hard-coded screen dimensions (320pt width assumption) which breaks on larger devices.

**Issues**:
- Hard-coded `KEYBOARD_HEIGHT 216.0f` doesn't account for different keyboard sizes on iPad
- Fixed width of `320.0f` used in `NNListViewController.m`
- Macros like `kScreenWidth` and `kScreenHeight` don't properly handle different device sizes and orientations

**Acceptance Criteria**:
- App layout adapts correctly to all iPhone and iPad screen sizes
- Keyboard height is determined dynamically using keyboard notifications
- Remove all hard-coded frame widths (320.0f references)
- Test on iPhone SE, iPhone 14 Pro Max, and iPad Pro

**Recommended Approach**:
```objc
// Replace hard-coded keyboard height with dynamic observation
[[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(keyboardWillShow:)
    name:UIKeyboardWillShowNotification
    object:nil];
```

---

### 2. Full Safe Area Layout Implementation
**Priority**: High
**Affected Files**: All view controllers
**Description**: Current safe area support is minimal. Need comprehensive safe area handling.

**Issues**:
- Text view positioning doesn't fully respect safe areas in landscape
- Toolbar positioning needs safe area adjustments
- Hard-coded insets don't account for different device safe areas

**Acceptance Criteria**:
- All UI elements respect safe area insets on notched devices
- Landscape orientation properly handles safe areas
- Works correctly on iPhone 14 Pro, iPhone 15 Pro Max

**Files to Update**:
- `NNViewController.m` (lines 157, 167, 432)
- `UNITaskCreatorViewController.m`
- `NNListViewController.m`

---

### 3. Modern App Icons via Asset Catalog
**Priority**: Medium
**Affected Files**: Project configuration
**Description**: Currently using individual PNG files for icons. Should migrate to Asset Catalog.

**Tasks**:
- Create `AppIcon` set in `Images.xcassets`
- Add all required icon sizes for iOS 12-17 (including 1024x1024 for App Store)
- Remove individual icon PNG files from project
- Update `NeverNote-Info.plist` to remove `CFBundleIcons` dictionary

**Acceptance Criteria**:
- App icon displays correctly on all devices and in App Store
- Project uses modern asset catalog structure
- No deprecation warnings related to icons

---

### 4. Keyboard Notification Improvements
**Priority**: Medium
**Affected Files**: `NNViewController.m`
**Description**: Replace hard-coded keyboard height with dynamic keyboard frame observation.

**Current Issue**:
```objc
#define KEYBOARD_HEIGHT 216.0f  // Wrong on iPad and with different keyboards
```

**Recommended Implementation**:
```objc
- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = keyboardFrame.size.height;
    // Update text view frame with actual keyboard height
}
```

**Acceptance Criteria**:
- Keyboard height adapts to different keyboard types
- Works with third-party keyboards
- Handles iPad floating keyboard correctly

---

### 5. Dark Mode Support
**Priority**: Medium
**Affected Files**: All view controllers
**Description**: Add native iOS 13+ dark mode support using UITraitCollection.

**Current State**: App has custom day/night mode via shake gesture
**Goal**: Integrate with system dark mode while maintaining custom toggle

**Tasks**:
- Override `traitCollectionDidChange:` in view controllers
- Update color scheme to use `UIColor` semantic colors or asset catalog colors
- Test appearance changes when system dark mode toggles
- Maintain existing shake gesture for manual override

**Acceptance Criteria**:
- App respects system dark mode setting
- Custom day/night toggle still works
- All text remains readable in both modes

---

## Medium Priority Tasks

### 6. Replace Deprecated UIApplication Status Bar Methods
**Priority**: Medium
**Affected Files**: `NNViewController.m`, `NNAppDelegate.m`
**Description**: While we updated to animated versions, status bar control should move to view controller-based approach.

**Current State**: Using deprecated UIApplication methods
**Recommended**: Switch to view controller-based status bar appearance

**Implementation**:
1. Set `UIViewControllerBasedStatusBarAppearance` to `YES` in Info.plist
2. Override `preferredStatusBarStyle` in each view controller
3. Call `setNeedsStatusBarAppearanceUpdate` instead of UIApplication methods

**Acceptance Criteria**:
- No status bar deprecation warnings
- Status bar appearance changes work correctly
- Works on iOS 12-17

---

### 7. Update Contact Picker Implementation
**Priority**: Medium
**Affected Files**: `NNContactViewController.m`, `NNContactViewController.h`
**Description**: Verify contact picker uses modern ContactsUI framework.

**Tasks**:
- Review `NNContactViewController.m` implementation
- Ensure using `CNContactPickerViewController` (iOS 9+) not deprecated AddressBook
- Add privacy usage descriptions to Info.plist if not present

**Acceptance Criteria**:
- Contact picker uses modern ContactsUI framework
- Privacy descriptions present in Info.plist
- No AddressBook framework usage

---

### 8. Add Scene Delegate Support (iOS 13+)
**Priority**: Low-Medium
**Affected Files**: New files, `NNAppDelegate.m`, Info.plist
**Description**: Add modern multi-window support via SceneDelegate.

**Tasks**:
- Create `SceneDelegate.h` and `SceneDelegate.m`
- Move window management to SceneDelegate
- Update Info.plist with UIApplicationSceneManifest
- Keep AppDelegate for backwards compatibility (iOS 12)

**Acceptance Criteria**:
- App supports multiple windows on iPadOS 13+
- Backwards compatible with iOS 12
- No window-related deprecation warnings

---

### 9. Update to Modern Core Data Stack
**Priority**: Low-Medium
**Affected Files**: `NNAppDelegate.m`
**Description**: Consider migrating to NSPersistentContainer (iOS 10+).

**Current**: Using manual NSPersistentStoreCoordinator setup
**Modern**: NSPersistentContainer provides simpler API

**Benefits**:
- Simpler, more maintainable code
- Better error handling
- Background context management built-in

**Acceptance Criteria**:
- Core Data stack uses NSPersistentContainer
- Existing data migrates successfully
- Unit tests verify data integrity

---

## Low Priority / Future Enhancements

### 10. Auto Layout Migration
**Priority**: Low
**Affected Files**: All view controllers
**Description**: Full migration from frame-based layout to Auto Layout.

**Scope**: Very large refactor - entire UI is frame-based
**Recommendation**: Consider for v2.0 or major refactor

**Benefits**:
- Better support for size classes
- Simpler rotation handling
- Future-proof for new devices

---

### 11. SwiftUI Bridging
**Priority**: Low
**Description**: Consider gradually introducing SwiftUI for new features.

**Recommendation**: Start with small, isolated features
**Example**: Settings screen, about screen

---

### 12. Unit Test Coverage
**Priority**: Low-Medium
**Affected Files**: `NeverNoteTests/`
**Description**: Add comprehensive unit test coverage.

**Current State**: Minimal test coverage
**Goal**: 60%+ code coverage

**Areas to Test**:
- Core Data operations
- Date/time utilities
- Color parsing logic
- Motion detection thresholds

---

### 13. Accessibility Improvements
**Priority**: Low-Medium
**Description**: Enhance VoiceOver and accessibility support.

**Tasks**:
- Add accessibility labels to custom UI elements
- Test with VoiceOver enabled
- Support Dynamic Type for text scaling
- Add accessibility hints for gesture-based features

**Note**: Line 973 in `NNViewController.m` has comment "Incompatible with voice over"

---

### 14. Performance Optimization
**Priority**: Low
**Affected Files**: `NNListViewController.m`
**Description**: Optimize table view and scroll view performance.

**Current Issues**:
- `NNListViewController.m` creates 3000+ table cells with random content
- No cell reuse optimization
- Heavy view creation in scroll view (lines 55-63)

**Recommendations**:
- Implement proper cell reuse
- Lazy load content
- Profile with Instruments

---

### 15. Modern Objective-C Syntax
**Priority**: Low
**Description**: Update to modern Objective-C conventions.

**Examples**:
- Use `instancetype` instead of `id` for init methods
- Use nullability annotations (`nullable`, `nonnull`)
- Use lightweight generics for collections
- Use `@property` with modern attributes

---

## Architecture Improvements

### 16. Separate UI from Business Logic
**Priority**: Low-Medium
**Description**: View controllers contain too much business logic.

**Recommendation**: Introduce MVVM or similar pattern
**Benefits**: Better testability, maintainability

---

### 17. Networking Layer (If Needed)
**Priority**: Low
**Description**: If app needs cloud sync, add modern networking.

**Recommendation**: Use NSURLSession with modern async patterns or third-party library like Alamofire

---

## Testing Checklist

Before release, test on:
- [ ] iPhone SE (2nd gen) - smallest screen
- [ ] iPhone 14 Pro - notch
- [ ] iPhone 15 Pro Max - Dynamic Island
- [ ] iPad Pro 12.9" - largest screen
- [ ] iOS 12 device (if possible)
- [ ] iOS 17.x device
- [ ] Test all orientations
- [ ] Test with VoiceOver enabled
- [ ] Test with Dark Mode on/off
- [ ] Test memory usage with Instruments
- [ ] Test Core Data migration from old version

---

## Known Technical Debt

### Code Smells
1. **NNViewController.m**: Extremely large file (1200+ lines) - should be refactored into smaller components
2. **Magic Numbers**: Many hard-coded values throughout codebase
3. **Color Parsing**: Lines 903-957 in `NNViewController.m` contain complex string parsing that should be externalized
4. **Motion Detection**: Complex state management in `startMotionDetect` could be simplified

### Platform Deprecations to Watch
- `UIGraphicsBeginImageContext` (line 983) - should use `UIGraphicsImageRenderer` on iOS 10+
- Manual date component manipulation - could use modern Calendar API improvements

---

## Migration Path Recommendation

### Phase 1 (Immediate - This PR)
✅ Deployment target update
✅ Launch screen modernization
✅ Critical deprecation fixes
✅ Basic safe area support

### Phase 2 (Next Release)
- [ ] Dynamic screen size support (#1)
- [ ] Full safe area implementation (#2)
- [ ] Keyboard notification improvements (#4)
- [ ] App icon migration (#3)

### Phase 3 (Future Release)
- [ ] Dark mode support (#5)
- [ ] View controller status bar (#6)
- [ ] Scene delegate (#8)
- [ ] Contact picker verification (#7)

### Phase 4 (Long-term)
- [ ] Auto Layout migration (#10)
- [ ] Architecture refactor (#16)
- [ ] Performance optimization (#14)
- [ ] Test coverage (#12)

---

## Resources

### Apple Documentation
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios)
- [Safe Area Layout Guide](https://developer.apple.com/documentation/uikit/uiview/2891102-safeareainsets)
- [Dark Mode](https://developer.apple.com/documentation/uikit/appearance_customization/supporting_dark_mode_in_your_interface)
- [Core Data Migration](https://developer.apple.com/documentation/coredata/using_lightweight_migration)

### Testing Tools
- Xcode Instruments for performance profiling
- Accessibility Inspector for VoiceOver testing
- View Debugger for layout issues

---

## Notes

**Backward Compatibility**: All changes maintain iOS 12+ compatibility using availability checks where needed.

**Breaking Changes**: None expected for existing users. Core Data migration is automatic and non-destructive.

**Review**: This document should be reviewed and updated after each release cycle.

---

**Last Updated**: 2025-11-15
**Project Version**: 1.0
**iOS Support**: 12.0 - 17.x
