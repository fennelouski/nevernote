//
//  NNOnboardingManager.m
//  NeverNote
//
//  Manages onboarding state and determines when to show onboarding tooltips.
//

#import "NNOnboardingManager.h"

// Notification names
NSString * const NNOnboardingDidStartNotification = @"NNOnboardingDidStartNotification";
NSString * const NNOnboardingStepDidChangeNotification = @"NNOnboardingStepDidChangeNotification";
NSString * const NNOnboardingDidCompleteNotification = @"NNOnboardingDidCompleteNotification";

// NSUserDefaults keys
static NSString * const kOnboardingCompletedKey = @"com.nevernote.onboardingCompleted";
static NSString * const kLastAppUseDateKey = @"com.nevernote.lastAppUseDate";
static NSString * const kCurrentOnboardingStepKey = @"com.nevernote.currentOnboardingStep";

// Constants
static const NSTimeInterval kInactivityThresholdDays = 30.0;

@interface NNOnboardingManager ()

@property (nonatomic, assign) BOOL isOnboardingActive;

@end

@implementation NNOnboardingManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static NNOnboardingManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isOnboardingActive = NO;
        [self loadState];
    }
    return self;
}

#pragma mark - State Management

- (void)loadState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Load current step
    NSInteger savedStep = [defaults integerForKey:kCurrentOnboardingStepKey];
    _currentStep = (NNOnboardingStep)savedStep;
}

- (void)saveState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.currentStep forKey:kCurrentOnboardingStepKey];
    [defaults synchronize];
}

#pragma mark - Public Properties

- (BOOL)hasCompletedOnboarding {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:kOnboardingCompletedKey];
}

- (BOOL)shouldShowOnboarding {
    // Show if not completed
    if (!self.hasCompletedOnboarding) {
        return YES;
    }

    // Show if inactive for 30+ days
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastUseDate = [defaults objectForKey:kLastAppUseDateKey];

    if (!lastUseDate) {
        return YES; // No last use date recorded
    }

    NSTimeInterval daysSinceLastUse = [[NSDate date] timeIntervalSinceDate:lastUseDate] / 86400.0;
    return daysSinceLastUse >= kInactivityThresholdDays;
}

#pragma mark - Public Methods

- (void)updateLastAppUseDate {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:kLastAppUseDateKey];
    [defaults synchronize];
}

- (void)startOnboarding {
    if (self.isOnboardingActive) {
        return; // Already active
    }

    self.isOnboardingActive = YES;
    self.currentStep = NNOnboardingStepWelcome;
    [self saveState];

    [[NSNotificationCenter defaultCenter] postNotificationName:NNOnboardingDidStartNotification
                                                        object:self];
}

- (void)nextStep {
    if (!self.isOnboardingActive) {
        return;
    }

    if (self.currentStep >= NNOnboardingStepCompleted) {
        [self completeOnboarding];
        return;
    }

    self.currentStep = (NNOnboardingStep)(self.currentStep + 1);
    [self saveState];

    [[NSNotificationCenter defaultCenter] postNotificationName:NNOnboardingStepDidChangeNotification
                                                        object:self
                                                      userInfo:@{@"step": @(self.currentStep)}];

    if (self.currentStep >= NNOnboardingStepCompleted) {
        [self completeOnboarding];
    }
}

- (void)skipToStep:(NNOnboardingStep)step {
    if (!self.isOnboardingActive) {
        return;
    }

    self.currentStep = step;
    [self saveState];

    [[NSNotificationCenter defaultCenter] postNotificationName:NNOnboardingStepDidChangeNotification
                                                        object:self
                                                      userInfo:@{@"step": @(self.currentStep)}];
}

- (void)completeOnboarding {
    self.isOnboardingActive = NO;
    self.currentStep = NNOnboardingStepCompleted;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kOnboardingCompletedKey];
    [defaults setInteger:NNOnboardingStepCompleted forKey:kCurrentOnboardingStepKey];
    [defaults synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:NNOnboardingDidCompleteNotification
                                                        object:self];
}

- (void)resetOnboarding {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kOnboardingCompletedKey];
    [defaults removeObjectForKey:kCurrentOnboardingStepKey];
    [defaults removeObjectForKey:kLastAppUseDateKey];
    [defaults synchronize];

    self.isOnboardingActive = NO;
    self.currentStep = NNOnboardingStepWelcome;
}

#pragma mark - Step Descriptions

- (NSString *)titleForStep:(NNOnboardingStep)step {
    switch (step) {
        case NNOnboardingStepWelcome:
            return @"Welcome to NeverNote!";
        case NNOnboardingStepTextEditing:
            return @"Quick Text Editing";
        case NNOnboardingStepGestures:
            return @"Powerful Gestures";
        case NNOnboardingStepSettings:
            return @"Customize Your Experience";
        case NNOnboardingStepTaskCreation:
            return @"Create Tasks";
        case NNOnboardingStepCompleted:
            return @"You're All Set!";
        default:
            return @"";
    }
}

- (NSString *)descriptionForStep:(NNOnboardingStep)step {
    switch (step) {
        case NNOnboardingStepWelcome:
            return @"Let's show you around! NeverNote is designed for lightning-fast note-taking with powerful gestures.";
        case NNOnboardingStepTextEditing:
            return @"Tap anywhere to start typing. Your notes are automatically saved as you type.";
        case NNOnboardingStepGestures:
            return @"Swipe left/right to navigate, swipe up to select text, swipe down to hide the keyboard. Pinch to adjust font size.";
        case NNOnboardingStepSettings:
            return @"Two-finger double-tap opens settings. Customize themes, fonts, and behavior to match your style.";
        case NNOnboardingStepTaskCreation:
            return @"Create tasks with due dates, categories, and reminders to stay organized.";
        case NNOnboardingStepCompleted:
            return @"You're ready to start taking notes! Remember: shake your device to toggle day/night mode.";
        default:
            return @"";
    }
}

@end
