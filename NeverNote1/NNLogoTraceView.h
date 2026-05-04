#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NNLogoTraceView : UIView

/// Wall-clock duration from `startAnimationWithCompletion:` until the overlay finishes fading out (launch handoff).
+ (NSTimeInterval)launchHandoffTotalDuration;

- (void)startAnimationWithCompletion:(void (^ _Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
