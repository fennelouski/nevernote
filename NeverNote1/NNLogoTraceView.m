#import "NNLogoTraceView.h"
#import "UIColor+AppColors.h"
#import <QuartzCore/QuartzCore.h>

@interface NNLogoTraceView ()

@property (nonatomic, strong) CALayer *animationContainerLayer;
@property (nonatomic, strong) NSArray<CAShapeLayer *> *strokeLayers;
@property (nonatomic, strong) CAShapeLayer *nibLayer;
@property (nonatomic, strong) CAShapeLayer *penTipLayer;
@property (nonatomic, copy, nullable) void (^completionBlock)(void);
@property (nonatomic, assign) BOOL hasPreparedLayers;
@property (nonatomic, assign) BOOL isAnimating;

@end

@implementation NNLogoTraceView

/// Matches product request: full launch-screen → app/editor handoff length.
static const NSTimeInterval kNNLogoLaunchHandoffSeconds = 1.247;
static const NSTimeInterval kNNLogoLaunchFadeOutSeconds = 0.12;
static const CFTimeInterval kNNLogoLaunchCAStartDelaySeconds = 0.008;
/// Time budget for the three stroke `strokeEnd` animations (nib/tip animations follow inside this tail).
static const CFTimeInterval kNNLogoLaunchStrokePhaseSeconds = 0.951;

+ (NSTimeInterval)launchHandoffTotalDuration {
    return kNNLogoLaunchHandoffSeconds;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor systemBackgroundColor];
    self.userInteractionEnabled = YES;

    _animationContainerLayer = [CALayer layer];
    [self.layer addSublayer:_animationContainerLayer];

    _hasPreparedLayers = NO;
    _isAnimating = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.animationContainerLayer.frame = self.bounds;
    [self prepareLayersIfNeeded];
}

- (void)prepareLayersIfNeeded {
    if (self.hasPreparedLayers && CGRectEqualToRect(self.animationContainerLayer.bounds, self.bounds)) {
        return;
    }

    [self.animationContainerLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];

    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat side = MIN(width, height) * 0.82;
    CGRect logoRect = CGRectMake((width - side) * 0.5, (height - side) * 0.5, side, side);

    UIColor *strokeColor = [UIColor appIconBlueColor];
    CGFloat lineWidth = MAX(8.0, side * 0.045);

    UIBezierPath *outerPath = [self outerPathInRect:logoRect];
    UIBezierPath *infinityPath = [self infinityPathInRect:logoRect];
    UIBezierPath *shaftPath = [self shaftPathInRect:logoRect];

    CAShapeLayer *outerLayer = [self strokeLayerForPath:outerPath color:strokeColor lineWidth:lineWidth];
    CAShapeLayer *infinityLayer = [self strokeLayerForPath:infinityPath color:strokeColor lineWidth:lineWidth];
    CAShapeLayer *shaftLayer = [self strokeLayerForPath:shaftPath color:strokeColor lineWidth:lineWidth];

    [self.animationContainerLayer addSublayer:outerLayer];
    [self.animationContainerLayer addSublayer:infinityLayer];
    [self.animationContainerLayer addSublayer:shaftLayer];
    self.strokeLayers = @[outerLayer, infinityLayer, shaftLayer];

    self.nibLayer = [self nibLayerInRect:logoRect color:strokeColor];
    self.nibLayer.opacity = 0.0;
    [self.animationContainerLayer addSublayer:self.nibLayer];

    self.penTipLayer = [self penTipLayerForLineWidth:lineWidth];
    self.penTipLayer.opacity = 0.0;
    [self.animationContainerLayer addSublayer:self.penTipLayer];

    self.hasPreparedLayers = YES;
}

- (void)startAnimationWithCompletion:(void (^ _Nullable)(void))completion {
    self.completionBlock = completion;
    [self prepareLayersIfNeeded];

    if (self.isAnimating) {
        return;
    }
    self.isAnimating = YES;

    if (UIAccessibilityIsReduceMotionEnabled()) {
        [self runReducedMotionAnimation];
        return;
    }

    [self animateStrokeDrawingSequence];
}

- (void)animateStrokeDrawingSequence {
    CFTimeInterval start = CACurrentMediaTime() + kNNLogoLaunchCAStartDelaySeconds;
    const double kStrokeSumRef = 0.88 + 0.58 + 0.32;
    const double scale = kNNLogoLaunchStrokePhaseSeconds / kStrokeSumRef;
    NSArray<NSNumber *> *durations = @[@(0.88 * scale), @(0.58 * scale), @(0.32 * scale)];
    NSArray<UIBezierPath *> *paths = @[
        [UIBezierPath bezierPathWithCGPath:self.strokeLayers[0].path],
        [UIBezierPath bezierPathWithCGPath:self.strokeLayers[1].path],
        [UIBezierPath bezierPathWithCGPath:self.strokeLayers[2].path]
    ];

    CFTimeInterval cursor = start;
    for (NSUInteger idx = 0; idx < self.strokeLayers.count; idx++) {
        CAShapeLayer *layer = self.strokeLayers[idx];
        CFTimeInterval duration = durations[idx].doubleValue;

        CABasicAnimation *draw = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        draw.fromValue = @0.0;
        draw.toValue = @1.0;
        draw.beginTime = cursor;
        draw.duration = duration;
        draw.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        draw.fillMode = kCAFillModeForwards;
        draw.removedOnCompletion = NO;
        [layer addAnimation:draw forKey:@"trace"];

        CAKeyframeAnimation *follow = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        follow.path = paths[idx].CGPath;
        follow.beginTime = cursor;
        follow.duration = duration;
        follow.calculationMode = kCAAnimationPaced;
        follow.rotationMode = kCAAnimationRotateAuto;
        follow.fillMode = kCAFillModeForwards;
        follow.removedOnCompletion = NO;
        [self.penTipLayer addAnimation:follow forKey:[NSString stringWithFormat:@"follow_%lu", (unsigned long)idx]];

        cursor += duration;
    }

    CABasicAnimation *tipIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    tipIn.fromValue = @0.0;
    tipIn.toValue = @1.0;
    tipIn.beginTime = start;
    tipIn.duration = MAX(0.03, 0.08 * scale);
    tipIn.fillMode = kCAFillModeForwards;
    tipIn.removedOnCompletion = NO;
    [self.penTipLayer addAnimation:tipIn forKey:@"tipIn"];

    CABasicAnimation *nibReveal = [CABasicAnimation animationWithKeyPath:@"opacity"];
    nibReveal.fromValue = @0.0;
    nibReveal.toValue = @1.0;
    nibReveal.beginTime = cursor - (0.08 * scale);
    nibReveal.duration = 0.2 * scale;
    nibReveal.fillMode = kCAFillModeForwards;
    nibReveal.removedOnCompletion = NO;
    [self.nibLayer addAnimation:nibReveal forKey:@"nibReveal"];

    CABasicAnimation *tipOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    tipOut.fromValue = @1.0;
    tipOut.toValue = @0.0;
    tipOut.beginTime = cursor + (0.02 * scale);
    tipOut.duration = 0.18 * scale;
    tipOut.fillMode = kCAFillModeForwards;
    tipOut.removedOnCompletion = NO;
    [self.penTipLayer addAnimation:tipOut forKey:@"tipOut"];

    NSTimeInterval fadeStart = kNNLogoLaunchHandoffSeconds - kNNLogoLaunchFadeOutSeconds;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fadeStart * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:kNNLogoLaunchFadeOutSeconds
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self finishAnimation];
        }];
    });
}

- (void)runReducedMotionAnimation {
    for (CAShapeLayer *layer in self.strokeLayers) {
        layer.strokeEnd = 1.0;
    }
    self.nibLayer.opacity = 1.0;
    self.alpha = 1.0;

    NSTimeInterval fadeStart = kNNLogoLaunchHandoffSeconds - kNNLogoLaunchFadeOutSeconds;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fadeStart * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:kNNLogoLaunchFadeOutSeconds
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self finishAnimation];
        }];
    });
}

- (void)finishAnimation {
    self.isAnimating = NO;
    if (self.completionBlock) {
        self.completionBlock();
        self.completionBlock = nil;
    }
}

#pragma mark - Layer Builders

- (CAShapeLayer *)strokeLayerForPath:(UIBezierPath *)path color:(UIColor *)color lineWidth:(CGFloat)lineWidth {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = path.CGPath;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = color.CGColor;
    layer.lineWidth = lineWidth;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    layer.strokeEnd = 0.0;
    return layer;
}

- (CAShapeLayer *)nibLayerInRect:(CGRect)rect color:(UIColor *)color {
    CGFloat (^X)(CGFloat) = ^CGFloat(CGFloat n) { return CGRectGetMinX(rect) + n * CGRectGetWidth(rect); };
    CGFloat (^Y)(CGFloat) = ^CGFloat(CGFloat n) { return CGRectGetMinY(rect) + n * CGRectGetHeight(rect); };

    UIBezierPath *nibPath = [UIBezierPath bezierPath];
    [nibPath moveToPoint:CGPointMake(X(0.905), Y(0.065))];
    [nibPath addLineToPoint:CGPointMake(X(0.820), Y(0.180))];
    [nibPath addLineToPoint:CGPointMake(X(0.810), Y(0.295))];
    [nibPath addLineToPoint:CGPointMake(X(0.895), Y(0.315))];
    [nibPath addLineToPoint:CGPointMake(X(0.982), Y(0.205))];
    [nibPath closePath];

    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = nibPath.CGPath;
    layer.fillColor = color.CGColor;
    layer.strokeColor = nil;

    CAShapeLayer *hole = [CAShapeLayer layer];
    UIBezierPath *holePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(X(0.872), Y(0.170), CGRectGetWidth(rect) * 0.034, CGRectGetWidth(rect) * 0.034)];
    hole.path = holePath.CGPath;
    hole.fillColor = [UIColor whiteColor].CGColor;
    [layer addSublayer:hole];

    return layer;
}

- (CAShapeLayer *)penTipLayerForLineWidth:(CGFloat)lineWidth {
    CAShapeLayer *layer = [CAShapeLayer layer];
    CGFloat dotSize = MAX(6.0, lineWidth * 0.58);
    UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-dotSize * 0.5, -dotSize * 0.5, dotSize, dotSize)];
    layer.path = dot.CGPath;
    layer.fillColor = [UIColor appIconBlueColor].CGColor;
    layer.strokeColor = nil;
    return layer;
}

#pragma mark - Paths

- (UIBezierPath *)outerPathInRect:(CGRect)rect {
    CGFloat (^X)(CGFloat) = ^CGFloat(CGFloat n) { return CGRectGetMinX(rect) + n * CGRectGetWidth(rect); };
    CGFloat (^Y)(CGFloat) = ^CGFloat(CGFloat n) { return CGRectGetMinY(rect) + n * CGRectGetHeight(rect); };

    UIBezierPath *path = [UIBezierPath bezierPath];
    // Long continuous backbone traced from the reference mark.
    [path moveToPoint:CGPointMake(X(0.085), Y(0.790))];
    [path addCurveToPoint:CGPointMake(X(0.205), Y(0.575))
            controlPoint1:CGPointMake(X(0.120), Y(0.710))
            controlPoint2:CGPointMake(X(0.155), Y(0.645))];
    [path addCurveToPoint:CGPointMake(X(0.245), Y(0.300))
            controlPoint1:CGPointMake(X(0.245), Y(0.495))
            controlPoint2:CGPointMake(X(0.250), Y(0.390))];
    [path addCurveToPoint:CGPointMake(X(0.360), Y(0.088))
            controlPoint1:CGPointMake(X(0.245), Y(0.190))
            controlPoint2:CGPointMake(X(0.295), Y(0.105))];
    [path addCurveToPoint:CGPointMake(X(0.585), Y(0.448))
            controlPoint1:CGPointMake(X(0.495), Y(0.052))
            controlPoint2:CGPointMake(X(0.560), Y(0.300))];
    [path addCurveToPoint:CGPointMake(X(0.750), Y(0.765))
            controlPoint1:CGPointMake(X(0.615), Y(0.610))
            controlPoint2:CGPointMake(X(0.675), Y(0.848))];
    [path addCurveToPoint:CGPointMake(X(0.888), Y(0.357))
            controlPoint1:CGPointMake(X(0.835), Y(0.690))
            controlPoint2:CGPointMake(X(0.865), Y(0.515))];
    return path;
}

- (UIBezierPath *)infinityPathInRect:(CGRect)rect {
    CGFloat (^X)(CGFloat) = ^CGFloat(CGFloat n) { return CGRectGetMinX(rect) + n * CGRectGetWidth(rect); };
    CGFloat (^Y)(CGFloat) = ^CGFloat(CGFloat n) { return CGRectGetMinY(rect) + n * CGRectGetHeight(rect); };

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(X(0.290), Y(0.492))];
    [path addCurveToPoint:CGPointMake(X(0.500), Y(0.565))
            controlPoint1:CGPointMake(X(0.365), Y(0.360))
            controlPoint2:CGPointMake(X(0.430), Y(0.548))];
    [path addCurveToPoint:CGPointMake(X(0.715), Y(0.475))
            controlPoint1:CGPointMake(X(0.575), Y(0.515))
            controlPoint2:CGPointMake(X(0.635), Y(0.360))];
    [path addCurveToPoint:CGPointMake(X(0.537), Y(0.388))
            controlPoint1:CGPointMake(X(0.768), Y(0.610))
            controlPoint2:CGPointMake(X(0.630), Y(0.425))];
    [path addCurveToPoint:CGPointMake(X(0.335), Y(0.530))
            controlPoint1:CGPointMake(X(0.430), Y(0.338))
            controlPoint2:CGPointMake(X(0.362), Y(0.404))];
    [path addCurveToPoint:CGPointMake(X(0.290), Y(0.492))
            controlPoint1:CGPointMake(X(0.305), Y(0.602))
            controlPoint2:CGPointMake(X(0.255), Y(0.534))];
    return path;
}

- (UIBezierPath *)shaftPathInRect:(CGRect)rect {
    CGFloat (^X)(CGFloat) = ^CGFloat(CGFloat n) { return CGRectGetMinX(rect) + n * CGRectGetWidth(rect); };
    CGFloat (^Y)(CGFloat) = ^CGFloat(CGFloat n) { return CGRectGetMinY(rect) + n * CGRectGetHeight(rect); };

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(X(0.794), Y(0.345))];
    [path addCurveToPoint:CGPointMake(X(0.890), Y(0.360))
            controlPoint1:CGPointMake(X(0.824), Y(0.350))
            controlPoint2:CGPointMake(X(0.860), Y(0.356))];
    return path;
}

@end
