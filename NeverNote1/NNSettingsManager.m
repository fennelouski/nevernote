//
//  NNSettingsManager.m
//  NeverNote
//
//  Settings manager for persistent app settings
//

#import "NNSettingsManager.h"

// NSUserDefaults keys
static NSString *const kThemeModeKey = @"com.nevernote.themeMode";
static NSString *const kFontNameKey = @"com.nevernote.fontName";
static NSString *const kFontSizeKey = @"com.nevernote.fontSize";
static NSString *const kTapToCopyEnabledKey = @"com.nevernote.tapToCopyEnabled";
static NSString *const kClearOnLaunchEnabledKey = @"com.nevernote.clearOnLaunchEnabled";
static NSString *const kMotionDetectionEnabledKey = @"com.nevernote.motionDetectionEnabled";
static NSString *const kAutoSaveEnabledKey = @"com.nevernote.autoSaveEnabled";
static NSString *const kShowKeyboardToolbarKey = @"com.nevernote.showKeyboardToolbar";
static NSString *const kHapticFeedbackEnabledKey = @"com.nevernote.hapticFeedbackEnabled";

@implementation NNSettingsManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static NNSettingsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadSettings];
    }
    return self;
}

#pragma mark - Load Settings

- (void)loadSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Check if this is first launch
    if (![defaults objectForKey:kThemeModeKey]) {
        [self resetToDefaults];
    } else {
        _themeMode = [defaults integerForKey:kThemeModeKey];
        _fontName = [defaults stringForKey:kFontNameKey];
        _fontSize = [defaults floatForKey:kFontSizeKey];
        _tapToCopyEnabled = [defaults boolForKey:kTapToCopyEnabledKey];
        _clearOnLaunchEnabled = [defaults boolForKey:kClearOnLaunchEnabledKey];
        _motionDetectionEnabled = [defaults boolForKey:kMotionDetectionEnabledKey];
        _autoSaveEnabled = [defaults boolForKey:kAutoSaveEnabledKey];
        _showKeyboardToolbar = [defaults boolForKey:kShowKeyboardToolbarKey];
        _hapticFeedbackEnabled = [defaults boolForKey:kHapticFeedbackEnabledKey];
    }
}

#pragma mark - Save Settings

- (void)saveSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setInteger:_themeMode forKey:kThemeModeKey];
    [defaults setObject:_fontName forKey:kFontNameKey];
    [defaults setFloat:_fontSize forKey:kFontSizeKey];
    [defaults setBool:_tapToCopyEnabled forKey:kTapToCopyEnabledKey];
    [defaults setBool:_clearOnLaunchEnabled forKey:kClearOnLaunchEnabledKey];
    [defaults setBool:_motionDetectionEnabled forKey:kMotionDetectionEnabledKey];
    [defaults setBool:_autoSaveEnabled forKey:kAutoSaveEnabledKey];
    [defaults setBool:_showKeyboardToolbar forKey:kShowKeyboardToolbarKey];
    [defaults setBool:_hapticFeedbackEnabled forKey:kHapticFeedbackEnabledKey];

    [defaults synchronize];

    // Post notification for settings change
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NNSettingsDidChangeNotification" object:nil];
}

#pragma mark - Property Setters

- (void)setThemeMode:(NNThemeMode)themeMode {
    _themeMode = themeMode;
    [self saveSettings];
}

- (void)setFontName:(NSString *)fontName {
    _fontName = fontName;
    [self saveSettings];
}

- (void)setFontSize:(CGFloat)fontSize {
    _fontSize = fontSize;
    [self saveSettings];
}

- (void)setTapToCopyEnabled:(BOOL)tapToCopyEnabled {
    _tapToCopyEnabled = tapToCopyEnabled;
    [self saveSettings];
}

- (void)setClearOnLaunchEnabled:(BOOL)clearOnLaunchEnabled {
    _clearOnLaunchEnabled = clearOnLaunchEnabled;
    [self saveSettings];
}

- (void)setMotionDetectionEnabled:(BOOL)motionDetectionEnabled {
    _motionDetectionEnabled = motionDetectionEnabled;
    [self saveSettings];
}

- (void)setAutoSaveEnabled:(BOOL)autoSaveEnabled {
    _autoSaveEnabled = autoSaveEnabled;
    [self saveSettings];
}

- (void)setShowKeyboardToolbar:(BOOL)showKeyboardToolbar {
    _showKeyboardToolbar = showKeyboardToolbar;
    [self saveSettings];
}

- (void)setHapticFeedbackEnabled:(BOOL)hapticFeedbackEnabled {
    _hapticFeedbackEnabled = hapticFeedbackEnabled;
    [self saveSettings];
}

#pragma mark - Reset to Defaults

- (void)resetToDefaults {
    _themeMode = NNThemeModeSystem;
    _fontName = @"System Bold";
    _fontSize = 18.0f;
    _tapToCopyEnabled = NO;
    _clearOnLaunchEnabled = NO;
    _motionDetectionEnabled = YES;
    _autoSaveEnabled = YES;
    _showKeyboardToolbar = YES;
    _hapticFeedbackEnabled = YES;

    [self saveSettings];
}

#pragma mark - Helper Methods

- (BOOL)shouldUseDarkMode {
    if (_themeMode == NNThemeModeLight) {
        return NO;
    } else if (_themeMode == NNThemeModeDark) {
        return YES;
    } else {
        // System mode - check trait collection
        if (@available(iOS 13.0, *)) {
            UITraitCollection *traitCollection = [UIScreen mainScreen].traitCollection;
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
        } else {
            // For iOS 12 and earlier, use time-based logic
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"HH"];
            NSInteger hour = [[df stringFromDate:[NSDate date]] integerValue];
            return (hour < 7 || hour >= 21);
        }
    }
}

@end
