//
//  NNOnboardingCoordinator.h
//  NeverNote
//
//  Coordinates the onboarding flow by showing tooltips one at a time.
//  Listens to NNOnboardingManager and presents appropriate tooltips.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Coordinates the onboarding flow, ensuring only one tooltip is shown at a time.
 * Automatically starts onboarding when conditions are met and manages the step-by-step flow.
 */
@interface NNOnboardingCoordinator : NSObject

/// Shared singleton instance
+ (instancetype)sharedCoordinator;

/// The root view controller where onboarding will be presented
@property (nonatomic, weak, nullable) UIViewController *rootViewController;

/**
 * Checks if onboarding should start and initiates it if needed.
 * Call this when the app becomes active.
 */
- (void)checkAndStartOnboarding;

/**
 * Manually starts the onboarding flow.
 */
- (void)startOnboarding;

/**
 * Stops the current onboarding flow.
 */
- (void)stopOnboarding;

@end

NS_ASSUME_NONNULL_END
