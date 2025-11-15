//
//  UNIAdditionalOptionsView.m
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "UNIAdditionalOptionsView.h"
#import "UIColor+AppColors.h"

// screen dimensions
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

// Additional Options
#define ADDITIONAL_OPTIONS_BUTTON_WIDTH 15.0f
#define ADDITIONAL_OPTIONS_BUTTON_HEIGHT ADDITIONAL_OPTIONS_BUTTON_WIDTH
#define ADDITIONAL_OPTIONS_ICON_SIZE 20.0f
#define ADDITIONAL_OPTIONS_CORNER_RADIUS 8.0f
#define ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH 45.0f
#define ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH
#define ADDITIONAL_OPTIONS_BUTTON_FONT_SIZE 10.0f

#define ANIMATION_DURATION 0.35f

#define TOOLBAR_HEIGHT 44.0f
#define TIME_FONT_SIZE 15.0f

@implementation UNIAdditionalOptionsView

- (instancetype)initWithAccountCount:(int)numberOfAccounts {
    self = [super init];
    
    if (self) {
        [self setIsSmall:YES];
        [self setFrame:CGRectMake(kScreenWidth - ADDITIONAL_OPTIONS_BUTTON_WIDTH, ADDITIONAL_OPTIONS_BUTTON_HEIGHT * 5, ADDITIONAL_OPTIONS_BUTTON_WIDTH * 3, ((numberOfAccounts > 1) ? 3 : 2) * ADDITIONAL_OPTIONS_BUTTON_HEIGHT + ADDITIONAL_OPTIONS_BUTTON_HEIGHT/6)];
        [self.layer setCornerRadius:ADDITIONAL_OPTIONS_CORNER_RADIUS];
        
        self.greyColor = [UIColor grayColor];
        self.smallFrame = self.frame;
        if (numberOfAccounts > 1) self.hasAccountButton = YES;
        
        if (self.hasAccountButton) [self addSubview:self.accountButton];
        [self addSubview:self.alarmButton];
        [self addSubview:self.repeatButton];
        
        
        self.largeFrame = CGRectMake(kScreenWidth - ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH, self.frame.origin.y, ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH * 1.5, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT*((numberOfAccounts > 1) ? 3 : 2));
        [self setSmallSizeBackgroundColor:[UIColor colorWithWhite:0.98f alpha:1.0f]];
        [self setBackgroundColor:self.smallSizeBackgroundColor];
        
        [self layoutSubviews];
    }
    
    return self;
}

#pragma mark - Buttons

- (UNIAdditionalOptionsViewButton *)accountButton {
    if (!_accountButton) {
        
        _accountButton = [[UNIAdditionalOptionsViewButton alloc] initWithFrame:CGRectMake(ADDITIONAL_OPTIONS_BUTTON_WIDTH/6, ADDITIONAL_OPTIONS_BUTTON_HEIGHT/5, ADDITIONAL_OPTIONS_BUTTON_WIDTH*4/6, ADDITIONAL_OPTIONS_BUTTON_HEIGHT*4/6)];
        
        [_accountButton setSmallFrame:_accountButton.frame];
        [_accountButton setLabel:self.accountLabel];
        [_accountButton addSubview:_accountButton.label];
        
        [_accountButton setLargeFrame:CGRectMake(self.largeFrame.origin.x, -ADDITIONAL_OPTIONS_BUTTON_HEIGHT / 3, ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT)];
        [_accountButton setLargeLabelCenter:CGPointMake(ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH/2, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT*6/7)];
        
        [_accountButton addTarget:self action:@selector(accountButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _accountButton;
}

- (UNIAdditionalOptionsViewButton *)alarmButton {
    if (!_alarmButton) {
        _alarmButton = [[UNIAdditionalOptionsViewButton alloc] initWithFrame:CGRectMake(ADDITIONAL_OPTIONS_BUTTON_WIDTH/6, ((self.hasAccountButton) ? ADDITIONAL_OPTIONS_BUTTON_HEIGHT : 0) + ADDITIONAL_OPTIONS_BUTTON_HEIGHT/5, ADDITIONAL_OPTIONS_BUTTON_WIDTH*4/6, ADDITIONAL_OPTIONS_BUTTON_HEIGHT*4/6)];
        
        [_alarmButton setSmallFrame:_alarmButton.frame];
        [_alarmButton setLabel:self.alarmLabel];
        [_alarmButton addSubview:_alarmButton.label];
        
        [_alarmButton setLargeFrame:CGRectMake(self.largeFrame.origin.x, ((self.hasAccountButton) ? ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT : 0) - ADDITIONAL_OPTIONS_BUTTON_HEIGHT / 3, ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT)];
        [_alarmButton setLargeLabelCenter:CGPointMake(ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH/2, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT*6/7)];
        
        [_alarmButton addTarget:self action:@selector(alarmButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _alarmButton;
}

- (UNIAdditionalOptionsViewButton *)repeatButton {
    if (!_repeatButton) {
        _repeatButton = [[UNIAdditionalOptionsViewButton alloc] initWithFrame:CGRectMake(-ADDITIONAL_OPTIONS_BUTTON_WIDTH/20, self.alarmButton.frame.origin.y + self.alarmButton.frame.size.height + ADDITIONAL_OPTIONS_BUTTON_HEIGHT/50, ADDITIONAL_OPTIONS_BUTTON_WIDTH*5/4, ADDITIONAL_OPTIONS_BUTTON_HEIGHT*5/4)];
        
        [_repeatButton setSmallFrame:_repeatButton.frame];
        [_repeatButton setLabel:self.repeatLabel];
        [_repeatButton addSubview:_repeatButton.label];
        
        [_repeatButton setLargeFrame:CGRectMake(self.largeFrame.origin.x + ADDITIONAL_OPTIONS_ICON_SIZE/10, ((self.hasAccountButton) ? ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT*2 : ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT) - ADDITIONAL_OPTIONS_BUTTON_HEIGHT / 4, ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT)];
        [_repeatButton setLargeLabelCenter:CGPointMake(ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH/2, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT*5/6)];
        
        [_repeatButton addTarget:self action:@selector(repeatButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _repeatButton;
}

#pragma mark - Labels

- (UILabel *)accountLabel {
    if (!_accountLabel) {
        _accountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT*2/3, ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT)];
        [_accountLabel setTextAlignment:NSTextAlignmentCenter];
        [_accountLabel setAlpha:0.0f];
    }
    
    return _accountLabel;
}

- (UILabel *)alarmLabel {
    if (!_alarmLabel) {
        _alarmLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT*2/3, ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT)];
        [_alarmLabel setTextAlignment:NSTextAlignmentCenter];
        [_alarmLabel setAlpha:0.0f];
    }
    
    return _alarmLabel;
}

- (UILabel *)repeatLabel {
    if (!_repeatLabel) {
        _repeatLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT*2/3, ADDITIONAL_OPTIONS_LARGE_BUTTON_WIDTH, ADDITIONAL_OPTIONS_LARGE_BUTTON_HEIGHT)];
        [_repeatLabel setTextAlignment:NSTextAlignmentCenter];
        [_repeatLabel setAlpha:0.0f];
    }
    
    return _repeatLabel;
}

#pragma mark - Background View

-(UIView *)background {
    if (!_background) {
        _background = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
        [_background setBackgroundColor:[UIColor colorWithWhite:0.2f alpha:1.0f]];
        [_background setAlpha:0.0f];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
        [tap setNumberOfTapsRequired:1];
        [tap setNumberOfTouchesRequired:1];
        [tap setDelegate:self];
        [_background addGestureRecognizer:tap];
        
//        [_background addTarget:self action:@selector(backgroundTouched:forEvent:) forControlEvents:UIControlEventTouchDown];
    }
    
    return _background;
}

#pragma mark - Switch Views

- (void)handleTap {
    [self switchView];
}

- (void)backgroundTouched:(UIButton *)button forEvent:(UIEvent *)event {
    UITouch *touch = [[event touchesForView:button] anyObject];
    CGPoint p = [touch locationInView:self.superview];
    if (!self.repeatShowing || p.y < kScreenHeight - self.repeatOptionsView.frame.size.height) {
        [self handleTap];
    }
}

- (void)switchView {
    if (!self.isAnimating) {
        self.isAnimating = YES;
        if (self.isSmall) {
            [self enlarge];
        }
        
        else {
            [self shrink];
        }
        
        [self.delegate switchView];
    }
}

- (void)enlarge {
    [self.layer setCornerRadius:ADDITIONAL_OPTIONS_CORNER_RADIUS];
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self setFrame:self.largeFrame];
        [self.accountButton setFrame:self.accountButton.largeFrame];
        [self.alarmButton setFrame:self.alarmButton.largeFrame];
        [self.repeatButton setFrame:self.repeatButton.largeFrame];
        [self.accountButton.label setCenter:self.accountButton.largeLabelCenter];
        [self.alarmButton.label setCenter:self.alarmButton.largeLabelCenter];
        [self.repeatButton.label setCenter:self.repeatButton.largeLabelCenter];
        [self.accountButton.label setAlpha:1.0f];
        [self.alarmButton.label setAlpha:1.0f];
        [self.repeatButton.label setAlpha:1.0f];
        [self setBackgroundColor:[UIColor systemBackgroundColor]];
    }completion:^(BOOL finished){
        self.isAnimating = NO;
        self.isSmall = NO;
    }];
    
    [UIView animateWithDuration:ANIMATION_DURATION delay:0.1f options:UIViewAnimationOptionCurveEaseOut animations:^{
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.background setBackgroundColor:[UIColor colorWithWhite:0.2f alpha:1.0f]];
        } completion:^(BOOL finished) {
            
        }];
    }];
    
}

- (void)shrink {
    [self dismissAlarmInput];
    [self dismissRepeatOptions];
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self setFrame:self.smallFrame];
        [self.accountButton setFrame:self.accountButton.smallFrame];
        [self.alarmButton setFrame:self.alarmButton.smallFrame];
        [self.repeatButton setFrame:self.repeatButton.smallFrame];
        [self.accountButton.label setCenter:self.accountButton.smallLabelCenter];
        [self.alarmButton.label setCenter:self.alarmButton.smallLabelCenter];
        [self.repeatButton.label setCenter:self.repeatButton.smallLabelCenter];
        [self.accountButton.label setAlpha:0.0f];
        [self.alarmButton.label setAlpha:0.0f];
        [self.repeatButton.label setAlpha:0.0f];
        [self setBackgroundColor:self.smallSizeBackgroundColor];
    }completion:^(BOOL finished){
        self.isAnimating = NO;
        self.isSmall = YES;
        self.alarmShowing = NO;
        self.repeatShowing = NO;
        [self.layer setCornerRadius:ADDITIONAL_OPTIONS_CORNER_RADIUS/2];
    }];
}

#pragma mark - Button Actions

- (void) accountButtonTouched {
    if (self.isSmall || self.isAnimating) {
        [self switchView];
        [self.delegate switchView];
        if ([self.delegate respondsToSelector:@selector(switchView)]) {
            NSLog(@"YES?");
        }
        else {
            NSLog(@"No?");
        }
    }
    
    else if ([self.delegate respondsToSelector:@selector(accountButtonTouched)]) {
        [self.delegate accountButtonTouched];
    }
    
    else {
        [self logDelegateError];
    }
}

- (void) alarmButtonTouched {
    if (self.isSmall || self.isAnimating) {
        [self switchView];
    }
    
    else if ([self.delegate respondsToSelector:@selector(alarmButtonTouched)] && !self.alarmShowing) {
        [self.delegate alarmButtonTouched];
        [self presentAlarmInput];
    }
    
    else if (self.alarmShowing) {
        
    }
    
    else {
        [self logDelegateError];
    }
}

- (void) repeatButtonTouched {
    if (self.isSmall || self.isAnimating) {
        [self switchView];
    }
    
    else if ([self.delegate respondsToSelector:@selector(repeatButtonTouched)] && !self.repeatShowing) {
        [self.delegate repeatButtonTouched];
        [self presentRepeatOptions];
    }
    
    else if (self.repeatShowing) {
        
    }
    
    else {
        [self logDelegateError];
    }
}

- (void)logDelegateError {
    NSLog(@"UNIAdditionalOptionsViewDelegate not assigned");
}

#pragma mark - Alarm Display Methods

- (void)presentAlarmInput {
    [self addSubview:self.timeInputToolbar];
    [self.timeInputTextField becomeFirstResponder];
    
    if (self.repeatShowing) {
        [self dismissRepeatOptions];
    }
    
    [UIView animateWithDuration:ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        [self.timeInputTextField becomeFirstResponder];
        [self.timeInputToolbar setBackgroundColor:[UIColor blueAppColor]];
    }completion:^(BOOL finished) {
        self.alarmShowing = YES;
    }];
    
    [self.timeInputView resetTimeInputView];
}

- (void)dismissAlarmInput {
    [self.timeInputTextField resignFirstResponder];
    self.alarmShowing = NO;
}

- (void)alarmTimeSelected:(NSDate *)alarmTime {
    if ([self.delegate respondsToSelector:@selector(alarmTimeSelected:)]) {
        [self.delegate alarmTimeSelected:alarmTime];
    }
}

#pragma mark - Images/Icons

- (UIImage *)accountCircle {
    CGSize circleSize = CGSizeMake(ADDITIONAL_OPTIONS_ICON_SIZE, ADDITIONAL_OPTIONS_ICON_SIZE);
    UIGraphicsBeginImageContext(circleSize);
    
    UIImage *circle = [UIImage new];
    
    UIGraphicsBeginImageContextWithOptions(circleSize, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    //// Oval drawing
    UIBezierPath *oval = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, ADDITIONAL_OPTIONS_ICON_SIZE, ADDITIONAL_OPTIONS_ICON_SIZE)];
    
    //Oval color fill
    [[UIColor blueAppColor] setFill];
    [oval fill];
    
    CGContextRestoreGState(ctx);
    circle = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return circle;
}

- (UIImage *)alarmClock {
    CGSize alarmClockSize = CGSizeMake(ADDITIONAL_OPTIONS_ICON_SIZE, ADDITIONAL_OPTIONS_ICON_SIZE);
    UIGraphicsBeginImageContext(alarmClockSize);
    
    UIImage *alarmClock = [UIImage new];
    
    UIGraphicsBeginImageContextWithOptions(alarmClockSize, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    
    //// Oval drawing
    UIBezierPath *oval = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, ADDITIONAL_OPTIONS_ICON_SIZE, ADDITIONAL_OPTIONS_ICON_SIZE)];
    
    //Oval color fill
    if (self.alarmEnabled) {
        [[UIColor blueAppColor] setFill];
    }
    
    else {
        [self.greyColor setFill];
    }
    
    [oval fill];
    
    //// Path drawing
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(ADDITIONAL_OPTIONS_ICON_SIZE/2, ADDITIONAL_OPTIONS_ICON_SIZE/2)];
    [path addLineToPoint:CGPointMake(ADDITIONAL_OPTIONS_ICON_SIZE/2, ADDITIONAL_OPTIONS_ICON_SIZE/6)];
    path.lineCapStyle = kCGLineCapRound;
    
    
    //Path color fill
    [[UIColor labelColor] setFill];
    [path fill];
    [[UIColor labelColor] setStroke];
    path.lineWidth = ADDITIONAL_OPTIONS_ICON_SIZE/14;
    [path stroke];

    //// Path2 drawing
    UIBezierPath *path2 = [UIBezierPath bezierPath];
    [path2 moveToPoint:CGPointMake(ADDITIONAL_OPTIONS_ICON_SIZE/2, ADDITIONAL_OPTIONS_ICON_SIZE/2)];
    [path2 addLineToPoint:CGPointMake(ADDITIONAL_OPTIONS_ICON_SIZE*5/6, ADDITIONAL_OPTIONS_ICON_SIZE/2)];
    path2.lineCapStyle = kCGLineCapRound;


    //Path2 color fill
    [[UIColor labelColor] setFill];
    [path2 fill];
    [[UIColor labelColor] setStroke];
    path2.lineWidth = ADDITIONAL_OPTIONS_ICON_SIZE/20;
    [path2 stroke];
    
    CGContextRestoreGState(ctx);
    alarmClock = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return alarmClock;
}

- (UIImage *)repeatIcon {
    float scale = 1/35.0f*ADDITIONAL_OPTIONS_ICON_SIZE;
    float xOffset = 10.0f;
    float yOffset = 10.0f;
    CGSize repeatIconSize = CGSizeMake(ADDITIONAL_OPTIONS_ICON_SIZE+xOffset*2, ADDITIONAL_OPTIONS_ICON_SIZE+yOffset*2);
    UIGraphicsBeginImageContext(repeatIconSize);
    
    UIImage *repeatIcon = [UIImage new];
    
    UIGraphicsBeginImageContextWithOptions(repeatIconSize, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    
    // Circle repeat icon
    //// Path drawing
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(26.552*scale+xOffset, 25.353*scale+yOffset)];
    [path addCurveToPoint:CGPointMake(30*scale+xOffset, 15.479*scale+yOffset) controlPoint1:CGPointMake(28.706*scale+xOffset, 22.673*scale+yOffset) controlPoint2:CGPointMake(30*scale+xOffset, 19.232*scale+yOffset)];
    [path addCurveToPoint:CGPointMake(15*scale+xOffset, 0*scale+yOffset) controlPoint1:CGPointMake(30*scale+xOffset, 6.93*scale+yOffset) controlPoint2:CGPointMake(23.284*scale+xOffset, 0*scale+yOffset)];
    [path addCurveToPoint:CGPointMake(0*scale+xOffset, 15.479*scale+yOffset) controlPoint1:CGPointMake(6.716*scale+xOffset, 0*scale+yOffset) controlPoint2:CGPointMake(0*scale+xOffset, 6.93*scale+yOffset)];
    [path addCurveToPoint:CGPointMake(9.794*scale+xOffset, 30*scale+yOffset) controlPoint1:CGPointMake(0*scale+xOffset, 22.139*scale+yOffset) controlPoint2:CGPointMake(4.076*scale+xOffset, 27.816*scale+yOffset)];
    [path addLineToPoint:CGPointMake(9.794*scale+xOffset, 30*scale+yOffset)];
    [path addLineToPoint:CGPointMake(10.257*scale+xOffset, 29.076*scale+yOffset)];
    [path addLineToPoint:CGPointMake(10.257*scale+xOffset, 29.076*scale+yOffset)];
    [path addCurveToPoint:CGPointMake(1*scale+xOffset, 15.479*scale+yOffset) controlPoint1:CGPointMake(4.859*scale+xOffset, 27.07*scale+yOffset) controlPoint2:CGPointMake(1*scale+xOffset, 21.74*scale+yOffset)];
    [path addCurveToPoint:CGPointMake(15*scale+xOffset, 1.032*scale+yOffset) controlPoint1:CGPointMake(1*scale+xOffset, 7.5*scale+yOffset) controlPoint2:CGPointMake(7.268*scale+xOffset, 1.032*scale+yOffset)];
    [path addCurveToPoint:CGPointMake(29*scale+xOffset, 15.479*scale+yOffset) controlPoint1:CGPointMake(22.732*scale+xOffset, 1.032*scale+yOffset) controlPoint2:CGPointMake(29*scale+xOffset, 7.5*scale+yOffset)];
    [path addCurveToPoint:CGPointMake(25.742*scale+xOffset, 24.744*scale+yOffset) controlPoint1:CGPointMake(29*scale+xOffset, 19.005*scale+yOffset) controlPoint2:CGPointMake(27.776*scale+xOffset, 22.236*scale+yOffset)];
    [path addLineToPoint:CGPointMake(23.789*scale+xOffset, 23.277*scale+yOffset)];
    [path addLineToPoint:CGPointMake(24.013*scale+xOffset, 28.164*scale+yOffset)];
    [path addLineToPoint:CGPointMake(28.588*scale+xOffset, 26.882*scale+yOffset)];
    [path addLineToPoint:CGPointMake(26.552*scale+xOffset, 25.353*scale+yOffset)];
    [path closePath];path.lineCapStyle = kCGLineCapRound;
    
    
    //Path color fill
    if (self.repeatEnabled) {
        [[UIColor blueAppColor] setFill];
        [[UIColor blueAppColor] setStroke];
    }
    
    else {
        [self.greyColor setFill];
        [self.greyColor setStroke];
    }
    path.lineWidth = 3;
    [path fill];
    [path stroke];
    
    
    //    // Rewind Repeat Icon
    //    //// Polygon drawing
    //    UIBezierPath *polygon = [UIBezierPath bezierPath];
    //    [polygon moveToPoint:CGPointMake(56*scale, 119*scale)];
    //    [polygon addLineToPoint:CGPointMake(213*scale, 237*scale)];
    //    [polygon addLineToPoint:CGPointMake(213*scale, 0*scale)];
    //    [polygon closePath];
    //
    //    //Polygon color fill
    //    if (self.repeatEnabled) {
    //        [[UIColor blueAppColor] setFill];
    //    }
    //
    //    else {
    //        [self.greyColor setFill];
    //    }
    //    [polygon fill];
    //
    //    //// Rectangle drawing
    //    UIBezierPath *rectangle = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 27*scale, 237*scale)];
    //
    //    //Rectangle color fill
    //    if (self.repeatEnabled) {
    //        [[UIColor blueAppColor] setFill];
    //    }
    //
    //    else {
    //        [self.greyColor setFill];
    //    }
    //    [rectangle fill];
    
    CGContextRestoreGState(ctx);
    repeatIcon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return repeatIcon;
}

#pragma mark - Time Input

- (UIToolbar *)timeInputToolbar {
    if (!_timeInputToolbar) {
        _timeInputToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, TOOLBAR_HEIGHT)];
        [_timeInputToolbar addSubview:self.timeInputTextField];
        [_timeInputToolbar setBarStyle:UIBarStyleDefault];
        [_timeInputToolbar setBarTintColor:[UIColor systemBackgroundColor]];
        [_timeInputToolbar setBackgroundColor:[UIColor clearColor]];
    }
    
    return _timeInputToolbar;
}

- (UITextField *)timeInputTextField {
    if (!_timeInputTextField) {
        _timeInputTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, TOOLBAR_HEIGHT)];
        [_timeInputTextField setInputView:self.timeInputView];
        [_timeInputTextField setInputAccessoryView:self.timeInputToolbar];
        
        [_timeInputTextField setAttributedText:[self hourTimeText:@"12:00p"]];
        
        [_timeInputTextField setTintColor:[UIColor colorWithWhite:0.97f alpha:0.00001f]];
        [_timeInputTextField setDelegate:self];
    }
    
    return _timeInputTextField;
}

- (UNITimeInputView *)timeInputView {
    if (!_timeInputView) {
        _timeInputView = [[UNITimeInputView alloc] init];
        [_timeInputView setDelegate:self];
    }
    
    return _timeInputView;
}

- (UNIRepeatOptionsView *)repeatOptionsView {
    if (!_repeatOptionsView) {
        _repeatOptionsView = [[UNIRepeatOptionsView alloc] init];
        [_repeatOptionsView setCenter:CGPointMake(-1*(self.center.x)/2 + (kScreenWidth - self.frame.origin.x) - 5.0f, kScreenHeight - _repeatOptionsView.frame.size.height/2 - self.center.y + 67.0f)];
        [_repeatOptionsView setDisplayCenter:_repeatOptionsView.center];
        [_repeatOptionsView setHiddenCenter:CGPointMake(_repeatOptionsView.center.x, _repeatOptionsView.center.y + _repeatOptionsView.frame.size.height*2)];
        [_repeatOptionsView setCenter:_repeatOptionsView.hiddenCenter];
        [_repeatOptionsView setDelegate:self];
    }
    
    return _repeatOptionsView;
}

#pragma mark - Time Input Delegate Methods

- (void)timeInputViewOutput:(NSString *)output {
//    [self.timeInputTextField setAttributedText:[self firstTimeText:@"12:00p"]];
    
    // set hour first
    if (!self.timeInputView.hourSet) {
        [self.timeInputTextField setAttributedText:[self minuteTimeText:[NSString stringWithFormat:@"%@:00p",output]]];
    }
    
    // check for ampm, it's easier
    else if ([[output lowercaseString] rangeOfString:@"a"].location != NSNotFound || [[output lowercaseString] rangeOfString:@"p"].location != NSNotFound) {
        [self.timeInputTextField setAttributedText:[self ampmTimeText:[NSString stringWithFormat:@"%@%@",[self.timeInputTextField.text substringToIndex:self.timeInputTextField.text.length - 1],[[output lowercaseString] substringToIndex:1]]]];
        self.timeInputView.hourSet = NO;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"h:mma"];
        [self alarmTimeSelected:[dateFormatter dateFromString:[[NSString stringWithFormat:@"%@m",self.timeInputTextField.text] uppercaseString]]];
    }
    
    // add minutes
    else {
        [self.timeInputTextField setAttributedText:[self ampmTimeText:[NSString stringWithFormat:@"%@:%@p", [self.timeInputTextField.text substringToIndex:[self.timeInputTextField.text rangeOfString:@":"].location], output]]];
    }
}

- (void)closeTimeInputView {
    [self switchView];
}

#pragma mark - Repeat Options

- (void) presentRepeatOptions {
    
    
    if (self.alarmShowing) {
        [self dismissAlarmInput];

        [self addSubview:self.repeatOptionsView];
        [self bringSubviewToFront:self.repeatOptionsView];
        
        [UIView animateWithDuration:0 animations:^{
            [self.repeatOptionsView setCenter:self.repeatOptionsView.displayCenter];
        }];
    }
    
    else {
        [self addSubview:self.repeatOptionsView];
        
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self.repeatOptionsView setCenter:self.repeatOptionsView.displayCenter];
        }];
    }
    
    self.repeatShowing = YES;
}

- (void) dismissRepeatOptions {
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.repeatOptionsView setCenter:self.repeatOptionsView.hiddenCenter];
    }];
    
    self.repeatShowing = NO;
}

- (void)repeatOptionSelected:(NSString *)option {
    [self dismissRepeatOptions];
    [self shrink];
    NSLog(@"%@", option);
    
    if ([self.delegate respondsToSelector:@selector(repeatOptionSelected:)]) {
        [self.delegate repeatOptionSelected:option];
    }
}

#pragma mark - Time Input symbols

- (NSAttributedString *)firstTimeText:(NSString *)input {
    // Create the attributed string
    NSMutableAttributedString *myString = [[NSMutableAttributedString alloc]initWithString:
                                           input];
    
    // Declare the fonts
    UIFont *myStringFont1 = [UIFont systemFontOfSize:TIME_FONT_SIZE];
    
    // Declare the colors
    UIColor *myStringColor1 = [UIColor grayColor];
    UIColor *myStringColor2 = [UIColor grayColor];
    
    // Declare the paragraph styles
    NSMutableParagraphStyle *myStringParaStyle1 = [[NSMutableParagraphStyle alloc]init];
    myStringParaStyle1.alignment = 1;
    
    
    // Create the attributes and add them to the string
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,6)];
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(0,6)];
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,6)];
    [myString addAttribute:NSForegroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,6)];
    
    return myString;
}

- (NSAttributedString *)hourTimeText:(NSString *)input {
    // Create the attributed string
    NSMutableAttributedString *myString = [[NSMutableAttributedString alloc]initWithString:
                                           input];
    
    // Declare the fonts
    UIFont *myStringFont1 = [UIFont systemFontOfSize:TIME_FONT_SIZE];
    
    // Declare the colors
    UIColor *myStringColor1 = [UIColor darkTextColor];
    UIColor *myStringColor2 = [UIColor blueAppColor];
    UIColor *myStringColor3 = [UIColor grayColor];
    
    // Declare the paragraph styles
    NSMutableParagraphStyle *myStringParaStyle1 = [[NSMutableParagraphStyle alloc]init];
    myStringParaStyle1.alignment = 1;
    
    long hourLength = [input rangeOfString:@":"].location;
    // Create the attributes and add them to the string
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSForegroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(hourLength,4)];
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(hourLength,4)];
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(hourLength,4)];
    [myString addAttribute:NSForegroundColorAttributeName value:myStringColor3 range:NSMakeRange(hourLength,4)];
    
    return myString;
}

- (NSAttributedString *)minuteTimeText:(NSString *)input {
    // Create the attributed string
    NSMutableAttributedString *myString = [[NSMutableAttributedString alloc]initWithString:
                                           input];
    
    // Declare the fonts
    UIFont *myStringFont1 = [UIFont systemFontOfSize:TIME_FONT_SIZE];
    
    // Declare the colors
    UIColor *myStringColor1 = [UIColor grayColor];
    UIColor *myStringColor2 = [UIColor grayColor];
    UIColor *myStringColor3 = [UIColor blueAppColor];
    
    // Declare the paragraph styles
    NSMutableParagraphStyle *myStringParaStyle1 = [[NSMutableParagraphStyle alloc]init];
    myStringParaStyle1.alignment = 1;
    
    long hourLength = [input rangeOfString:@":"].location + 1;
    
    // Create the attributes and add them to the string
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSForegroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(hourLength,2)];
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(hourLength,2)];
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(hourLength,2)];
    [myString addAttribute:NSForegroundColorAttributeName value:myStringColor3 range:NSMakeRange(hourLength,2)];
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(hourLength+2,1)];
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(hourLength+2,1)];
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(hourLength+2,1)];
    [myString addAttribute:NSForegroundColorAttributeName value:myStringColor2 range:NSMakeRange(hourLength+2,1)];
    
    return myString;
}

- (NSAttributedString *)ampmTimeText:(NSString *)input {
    // Create the attributed string
    NSMutableAttributedString *myString = [[NSMutableAttributedString alloc]initWithString:
                                           input];
    
    // Declare the fonts
    UIFont *myStringFont1 = [UIFont systemFontOfSize:TIME_FONT_SIZE];
    
    // Declare the colors
    UIColor *myStringColor1 = [UIColor grayColor];
    UIColor *myStringColor2 = [UIColor grayColor];
    UIColor *myStringColor3 = [UIColor blueAppColor];
    
    // Declare the paragraph styles
    NSMutableParagraphStyle *myStringParaStyle1 = [[NSMutableParagraphStyle alloc]init];
    myStringParaStyle1.alignment = 1;
    
    long hourLength = [input rangeOfString:@":"].location + 3;
    // Create the attributes and add them to the string
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSForegroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,hourLength)];
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(hourLength,1)];
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(hourLength,1)];
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(hourLength,1)];
    [myString addAttribute:NSForegroundColorAttributeName value:myStringColor3 range:NSMakeRange(hourLength,1)];
    
    return myString;
}

#pragma mark - Layout Subviews

- (void)layoutSubviews {
    // Labels
    [_accountLabel setText:@"account"];
    [_accountLabel setTextColor:self.greyColor];
    [_accountLabel setFont:[UIFont systemFontOfSize:ADDITIONAL_OPTIONS_BUTTON_FONT_SIZE]];
    
    [_alarmLabel setText:@"alarm"];
    [_alarmLabel setTextColor:(self.alarmEnabled) ? [UIColor blueAppColor] : self.greyColor];
    [_alarmLabel setFont:[UIFont systemFontOfSize:ADDITIONAL_OPTIONS_BUTTON_FONT_SIZE]];
    
    [_repeatLabel setText:@"repeat"];
    [_repeatLabel setTextColor:(self.repeatEnabled) ? [UIColor blueAppColor] : self.greyColor];
    [_repeatLabel setFont:[UIFont systemFontOfSize:ADDITIONAL_OPTIONS_BUTTON_FONT_SIZE]];
    
    // Buttons
    [_accountButton setImage:[self accountCircle] forState:UIControlStateNormal];
    [_alarmButton setImage:[self alarmClock] forState:UIControlStateNormal];
    [_repeatButton setImage:[self repeatIcon] forState:UIControlStateNormal];
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (CGRectContainsPoint(self.repeatOptionsView.frame, [touch locationInView:self])) {
        [self.repeatOptionsView repeatOptionViewManuallyTouched:touch];
    }
    
    return YES;
}

#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // This should be formatted to allow bluetooth keyboards and voice dictation
    return NO;
}

@end
