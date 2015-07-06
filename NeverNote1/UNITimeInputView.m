//
//  UNITimeInputView.m
//  Donebox
//
//  Created by Nathan Fennel on 7/6/14.
//  Copyright (c) 2014 Troy Chmieleski. All rights reserved.
//

#import "UNITimeInputView.h"
#import "UIColor+AppColors.h"

// Screen dimensions
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kKeyboardHeight 214.0f

// Font Size
#define FONT_SIZE 18.0f
#define TIME_FONT_SIZE 30.0f

// Toolbar sizes
#define TOOLBAR_HEIGHT 44.0f
#define TIME_TOOLBAR_HEIGHT 50.0f

// define bubble border properties
#define CORNER_RADIUS 6.0f
#define DELINEATOR_WIDTH 0.5f
#define BUBBLE_BUFFER 6.0f

@implementation UNITimeInputView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, kScreenWidth, kKeyboardHeight)];
    
    if (self) {
        self.hourSet = NO;
        self.rows = 4;
        self.columns = 3;
        self.hours = [[NSMutableArray alloc] initWithCapacity:12];
        for (int i = 1; i <= 12; i++) {[self.hours addObject:[NSNumber numberWithInt:i]];}
        [self addSubview:self.hourView];
    }
    
    return self;
}

#pragma mark - Hour View

- (UIView *)hourView {
    if (!_hourView) {
        _hourView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        
        for (int i = 0; i < self.hours.count; i++) {
            [_hourView addSubview:[self numberButton:i]];
        }
    }
    
    return _hourView;
}

- (UIButton *)numberButton:(int)position {
    CGRect frame = CGRectMake((position % self.columns) * kScreenWidth / self.columns, ((position/self.columns) % self.rows) * kKeyboardHeight / self.rows, kScreenWidth/self.columns, kKeyboardHeight/self.rows);
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    [button setTitle:[NSString stringWithFormat:@"%d", [self.hours[position] intValue]] forState:UIControlStateNormal];
    [self formatButton:button];
    [button addTarget:self action:@selector(hourButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)hourButtonTouched:(UIButton *)button {
    [self timeInputViewOutput:button.titleLabel.text];
    self.hourSet = YES;
    
    [self.hourView removeFromSuperview];
    [self addSubview:self.minuteView];
}

#pragma mark - Minute View

- (UIView *)minuteView {
    if (!_minuteView) {
        _minuteView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.minutes = [[NSMutableArray alloc] initWithArray:@[@"00",@"15",@"30",@"45"]];
        for (int i = 0; i < self.minutes.count; i++) {
            [_minuteView addSubview:[self minuteButton:i]];
        }
        
        self.ampm = [[NSMutableArray alloc] initWithArray:@[@"AM",@"PM"]];
        for (int i = 0; i < self.ampm.count; i++) {
            [_minuteView addSubview:[self ampmButton:i]];
        }
    }
    
    return _minuteView;
}

- (UIButton *)minuteButton:(int)position {
    CGRect frame = CGRectMake((position % 2) * kScreenWidth / 2, ((position/2) % 2) * kKeyboardHeight*2/5, kScreenWidth/2, kKeyboardHeight*2/5);
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    [button setTitle:self.minutes[position] forState:UIControlStateNormal];
    [self formatButton:button];
    [button addTarget:self action:@selector(minuteButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (UIButton *)ampmButton:(int)position {
    CGRect frame = CGRectMake((position % 2) * kScreenWidth / 2, kKeyboardHeight*4/5, kScreenWidth/2, kKeyboardHeight/5);
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    [self formatButton:button];
    [button setTitle:self.ampm[position] forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:TIME_FONT_SIZE/2]];
    [button addTarget:self action:@selector(ampmButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)minuteButtonTouched:(UIButton *)button {
    [self timeInputViewOutput:button.titleLabel.text];
}

- (void)ampmButtonTouched:(UIButton *)button {
    [self timeInputViewOutput:button.titleLabel.text];
    [self closeTimeInputView];
}

#pragma mark - Delegate Methods

- (void)timeInputViewOutput:(NSString *)output {
    if ([self.delegate respondsToSelector:@selector(timeInputViewOutput:)]) {
        [self.delegate timeInputViewOutput:output];
    }
    
    else {
        [self logDelegateError];
    }
}

- (void)closeTimeInputView {
    if ([self.delegate respondsToSelector:@selector(closeTimeInputView)]) {
        [self.delegate closeTimeInputView];
    }
    
    else {
        [self logDelegateError];
    }
}

- (void)logDelegateError {
    NSLog(@"UNITimeInputView Delegate Method not assigned");
}


#pragma mark - reset View

- (void)resetTimeInputView {
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    [self addSubview:self.hourView];
}

#pragma mark - Button Creator Helper

- (void) formatButton:(UIButton *)button {
    [button.titleLabel setFont:[UIFont systemFontOfSize:TIME_FONT_SIZE]];
    [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor lightKeyboardBackgroundColor]];
    [button.layer setBorderColor:[UIColor lightNumberPadKeyBorderColor].CGColor];
    [button.layer setBorderWidth:DELINEATOR_WIDTH];
}

@end
