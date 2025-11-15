//
//  NNOnboardingTooltipView.h
//  NeverNote
//
//  A tooltip view that displays onboarding guidance one step at a time.
//  Features a semi-transparent overlay with a spotlight effect on target areas.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NNOnboardingTooltipView;

@protocol NNOnboardingTooltipViewDelegate <NSObject>

@optional

/// Called when the user taps the "Next" button
- (void)onboardingTooltipViewDidTapNext:(NNOnboardingTooltipView *)tooltipView;

/// Called when the user taps the "Skip" button
- (void)onboardingTooltipViewDidTapSkip:(NNOnboardingTooltipView *)tooltipView;

@end

/**
 * A view that displays onboarding tooltips with a semi-transparent overlay.
 * Only one tooltip is shown at a time to avoid overwhelming the user.
 */
@interface NNOnboardingTooltipView : UIView

/// Delegate for handling user interactions
@property (nonatomic, weak, nullable) id<NNOnboardingTooltipViewDelegate> delegate;

/// The title text displayed in the tooltip
@property (nonatomic, copy) NSString *titleText;

/// The description text displayed in the tooltip
@property (nonatomic, copy) NSString *descriptionText;

/// Optional target rect to highlight with a spotlight effect (in window coordinates)
@property (nonatomic, assign) CGRect targetRect;

/// Whether to show the spotlight effect
@property (nonatomic, assign) BOOL showsSpotlight;

/// Whether to show the "Skip" button
@property (nonatomic, assign) BOOL showsSkipButton;

/**
 * Convenience initializer with title and description
 */
- (instancetype)initWithTitle:(NSString *)title
                  description:(NSString *)description;

/**
 * Shows the tooltip with an animation
 */
- (void)show;

/**
 * Dismisses the tooltip with an animation
 */
- (void)dismissWithCompletion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
