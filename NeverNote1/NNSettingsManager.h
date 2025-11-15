//
//  NNSettingsManager.h
//  NeverNote
//
//  Settings manager for persistent app settings
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NNThemeMode) {
    NNThemeModeSystem = 0,
    NNThemeModeLight = 1,
    NNThemeModeDark = 2
};

@interface NNSettingsManager : NSObject

// Singleton instance
+ (instancetype)sharedManager;

// Theme Settings
@property (nonatomic, assign) NNThemeMode themeMode;

// Font Settings
@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, assign) CGFloat fontSize;

// Behavior Settings
@property (nonatomic, assign) BOOL tapToCopyEnabled;
@property (nonatomic, assign) BOOL clearOnLaunchEnabled;
@property (nonatomic, assign) BOOL motionDetectionEnabled;
@property (nonatomic, assign) BOOL autoSaveEnabled;

// Keyboard Settings
@property (nonatomic, assign) BOOL showKeyboardToolbar;

// Advanced Settings
@property (nonatomic, assign) BOOL hapticFeedbackEnabled;

// Methods
- (void)resetToDefaults;
- (BOOL)shouldUseDarkMode; // Returns YES if dark mode should be used based on settings

@end
