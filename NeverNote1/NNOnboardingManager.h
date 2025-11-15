//
//  NNOnboardingManager.h
//  NeverNote
//
//  Manages onboarding state and determines when to show onboarding tooltips.
//  Shows onboarding if user hasn't completed it OR hasn't used app in 30+ days.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Notification posted when onboarding should start
extern NSString * const NNOnboardingDidStartNotification;

/// Notification posted when onboarding step changes
extern NSString * const NNOnboardingStepDidChangeNotification;

/// Notification posted when onboarding completes
extern NSString * const NNOnboardingDidCompleteNotification;

/// Defines the steps in the onboarding flow
typedef NS_ENUM(NSInteger, NNOnboardingStep) {
    NNOnboardingStepWelcome = 0,
    NNOnboardingStepTextEditing,
    NNOnboardingStepGestures,
    NNOnboardingStepSettings,
    NNOnboardingStepTaskCreation,
    NNOnboardingStepCompleted
};

/**
 * Singleton manager that tracks onboarding state and progress.
 * Uses NSUserDefaults to persist:
 * - Onboarding completion status
 * - Last app use date
 * - Current onboarding step
 */
@interface NNOnboardingManager : NSObject

/// Shared singleton instance
+ (instancetype)sharedManager;

/// Whether onboarding should be shown (not completed OR last use > 30 days ago)
@property (nonatomic, readonly) BOOL shouldShowOnboarding;

/// Whether onboarding has been completed
@property (nonatomic, readonly) BOOL hasCompletedOnboarding;

/// Current step in the onboarding flow
@property (nonatomic, assign) NNOnboardingStep currentStep;

/// Whether onboarding is currently active
@property (nonatomic, readonly) BOOL isOnboardingActive;

/// Updates the last app use date to now
- (void)updateLastAppUseDate;

/// Starts the onboarding flow
- (void)startOnboarding;

/// Advances to the next onboarding step
- (void)nextStep;

/// Skips to a specific step
- (void)skipToStep:(NNOnboardingStep)step;

/// Completes onboarding and marks it as finished
- (void)completeOnboarding;

/// Resets onboarding state (for testing/debugging)
- (void)resetOnboarding;

/// Returns a user-friendly title for a given step
- (NSString *)titleForStep:(NNOnboardingStep)step;

/// Returns a user-friendly description for a given step
- (NSString *)descriptionForStep:(NNOnboardingStep)step;

@end

NS_ASSUME_NONNULL_END
