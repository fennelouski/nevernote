//
//  NNOnboardingTooltipView.m
//  NeverNote
//
//  A tooltip view that displays onboarding guidance one step at a time.
//

#import "NNOnboardingTooltipView.h"
#import "UIColor+AppColors.h"

@interface NNOnboardingTooltipView ()

@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *skipButton;

@end

@implementation NNOnboardingTooltipView

#pragma mark - Initialization

- (instancetype)initWithTitle:(NSString *)title description:(NSString *)description {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _titleText = [title copy];
        _descriptionText = [description copy];
        _showsSpotlight = NO;
        _showsSkipButton = YES;
        _targetRect = CGRectZero;
        [self setupViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _showsSpotlight = NO;
        _showsSkipButton = YES;
        _targetRect = CGRectZero;
        [self setupViews];
    }
    return self;
}

#pragma mark - Setup

- (void)setupViews {
    self.backgroundColor = [UIColor clearColor];

    // Overlay view with semi-transparent background
    self.overlayView = [[UIView alloc] init];
    self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    [self addSubview:self.overlayView];

    // Content view for the tooltip card
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 12.0;
    self.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.contentView.layer.shadowOffset = CGSizeMake(0, 4);
    self.contentView.layer.shadowOpacity = 0.3;
    self.contentView.layer.shadowRadius = 8.0;
    [self addSubview:self.contentView];

    // Title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLabel];

    // Description label
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.font = [UIFont systemFontOfSize:16.0];
    self.descriptionLabel.textColor = [UIColor darkGrayColor];
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.descriptionLabel];

    // Next button
    self.nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.nextButton setTitle:@"Next" forState:UIControlStateNormal];
    self.nextButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.nextButton.backgroundColor = [UIColor systemBlueColor];
    self.nextButton.layer.cornerRadius = 8.0;
    [self.nextButton addTarget:self action:@selector(nextButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.nextButton];

    // Skip button
    self.skipButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.skipButton setTitle:@"Skip" forState:UIControlStateNormal];
    self.skipButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [self.skipButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [self.skipButton addTarget:self action:@selector(skipButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.skipButton];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = self.bounds;

    // Overlay covers entire view
    self.overlayView.frame = bounds;

    // Content view positioned near bottom (or centered if spotlight is active)
    CGFloat contentWidth = MIN(bounds.size.width - 40.0, 400.0);
    CGFloat padding = 20.0;
    CGFloat buttonHeight = 44.0;
    CGFloat spacing = 12.0;

    // Calculate heights
    CGFloat titleHeight = [self heightForText:self.titleText
                                         font:self.titleLabel.font
                                        width:contentWidth - (padding * 2)];
    CGFloat descHeight = [self heightForText:self.descriptionText
                                        font:self.descriptionLabel.font
                                       width:contentWidth - (padding * 2)];

    CGFloat contentHeight = padding + titleHeight + spacing + descHeight + spacing + buttonHeight;
    if (self.showsSkipButton) {
        contentHeight += buttonHeight / 2;
    }
    contentHeight += padding;

    CGFloat contentX = (bounds.size.width - contentWidth) / 2.0;
    CGFloat contentY = bounds.size.height - contentHeight - 40.0;

    // If spotlight is active, position content above or below the target
    if (self.showsSpotlight && !CGRectIsEmpty(self.targetRect)) {
        CGFloat targetMaxY = CGRectGetMaxY(self.targetRect);
        CGFloat targetMinY = CGRectGetMinY(self.targetRect);

        // Try to position below the target
        if (targetMaxY + contentHeight + 20.0 < bounds.size.height) {
            contentY = targetMaxY + 20.0;
        } else if (targetMinY - contentHeight - 20.0 > 0) {
            // Position above the target
            contentY = targetMinY - contentHeight - 20.0;
        } else {
            // Center it
            contentY = (bounds.size.height - contentHeight) / 2.0;
        }
    }

    self.contentView.frame = CGRectMake(contentX, contentY, contentWidth, contentHeight);

    // Layout content view subviews
    CGFloat currentY = padding;

    self.titleLabel.frame = CGRectMake(padding, currentY, contentWidth - (padding * 2), titleHeight);
    currentY += titleHeight + spacing;

    self.descriptionLabel.frame = CGRectMake(padding, currentY, contentWidth - (padding * 2), descHeight);
    currentY += descHeight + spacing;

    self.nextButton.frame = CGRectMake(padding, currentY, contentWidth - (padding * 2), buttonHeight);
    currentY += buttonHeight;

    if (self.showsSkipButton) {
        currentY += spacing / 2;
        self.skipButton.frame = CGRectMake(padding, currentY, contentWidth - (padding * 2), buttonHeight / 2);
    }

    self.skipButton.hidden = !self.showsSkipButton;
}

- (CGFloat)heightForText:(NSString *)text font:(UIFont *)font width:(CGFloat)width {
    if (!text || text.length == 0) {
        return 0;
    }

    CGSize constraintSize = CGSizeMake(width, CGFLOAT_MAX);
    CGRect textRect = [text boundingRectWithSize:constraintSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName: font}
                                         context:nil];
    return ceil(textRect.size.height);
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    if (self.showsSpotlight && !CGRectIsEmpty(self.targetRect)) {
        CGContextRef context = UIGraphicsGetCurrentContext();

        // Draw the overlay with a cutout for the spotlight
        CGContextSetFillColorWithColor(context, [[UIColor blackColor] colorWithAlphaComponent:0.7].CGColor);
        CGContextFillRect(context, rect);

        // Clear the spotlight area
        CGRect spotlightRect = CGRectInset(self.targetRect, -8.0, -8.0);
        CGContextSetBlendMode(context, kCGBlendModeClear);
        UIBezierPath *spotlightPath = [UIBezierPath bezierPathWithRoundedRect:spotlightRect cornerRadius:8.0];
        CGContextAddPath(context, spotlightPath.CGPath);
        CGContextFillPath(context);

        // Draw a subtle border around the spotlight
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] colorWithAlphaComponent:0.8].CGColor);
        CGContextSetLineWidth(context, 2.0);
        CGContextAddPath(context, spotlightPath.CGPath);
        CGContextStrokePath(context);
    }
}

#pragma mark - Public Methods

- (void)setTitleText:(NSString *)titleText {
    _titleText = [titleText copy];
    self.titleLabel.text = titleText;
    [self setNeedsLayout];
}

- (void)setDescriptionText:(NSString *)descriptionText {
    _descriptionText = [descriptionText copy];
    self.descriptionLabel.text = descriptionText;
    [self setNeedsLayout];
}

- (void)setTargetRect:(CGRect)targetRect {
    _targetRect = targetRect;
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

- (void)setShowsSpotlight:(BOOL)showsSpotlight {
    _showsSpotlight = showsSpotlight;
    self.overlayView.hidden = showsSpotlight; // Hide overlay view when using custom drawing
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

- (void)setShowsSkipButton:(BOOL)showsSkipButton {
    _showsSkipButton = showsSkipButton;
    [self setNeedsLayout];
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }

    if (!window) {
        return;
    }

    self.frame = window.bounds;
    [window addSubview:self];

    // Update labels
    self.titleLabel.text = self.titleText;
    self.descriptionLabel.text = self.descriptionText;

    // Animate in
    self.alpha = 0.0;
    self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);

    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.alpha = 1.0;
        self.contentView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismissWithCompletion:(void (^)(void))completion {
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.alpha = 0.0;
        self.contentView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Actions

- (void)nextButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(onboardingTooltipViewDidTapNext:)]) {
        [self.delegate onboardingTooltipViewDidTapNext:self];
    }
}

- (void)skipButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(onboardingTooltipViewDidTapSkip:)]) {
        [self.delegate onboardingTooltipViewDidTapSkip:self];
    }
}

@end
