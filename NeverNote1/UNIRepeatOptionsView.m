//
//  UNIRepeatOptionsView.m
//  NeverNote
//
//  Created by Nathan Fennel on 7/7/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "UNIRepeatOptionsView.h"
#import "UIColor+AppColors.h"

// Screen dimensions
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kKeyboardHeight 214.0f


#define DELINEATOR_WIDTH 0.5f

@implementation UNIRepeatOptionsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self setFrame:CGRectMake(-5.0f, kScreenHeight - kKeyboardHeight, kScreenWidth + 10.0f, kKeyboardHeight)];
        _options = [NSMutableArray arrayWithArray:@[@"None",@"Daily",@"Weekdays",@"Weekly",@"Bi-Weekly",@"Monthly"]];
        self.rows = 2;
        self.columns = 3;
        
        [self layoutSubviews];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(repeatOptionSelected:)];
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (UIButton *)repeatOptionButtonForPosition:(int)position {
    CGRect frame = CGRectMake((position % self.columns) * self.frame.size.width/self.columns, (position/self.columns) * kKeyboardHeight/self.rows, self.frame.size.width/self.columns, kKeyboardHeight/self.rows);
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    
    [button setTitle:self.options[position] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor lightKeyboardBackgroundColor]];
    [button.layer setBorderWidth:DELINEATOR_WIDTH];
    [button.layer setBorderColor:[UIColor lightNumberPadKeyBorderColor].CGColor];
    [button addTarget:self action:@selector(repeatOptionSelected:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)repeatOptionViewManuallyTouched:(UITouch *)touch {
    CGPoint p = [touch locationInView:self];
    
    for (UIButton *button in self.subviews) {
        if (CGRectContainsPoint(button.frame, p)) {
            [self repeatOptionSelected:button];
            
            break;
        }
    }
}

- (void)repeatOptionSelected:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(repeatOptionSelected:)]) {
        [self.delegate repeatOptionSelected:button.titleLabel.text];
    }
    
    else {
        NSLog(@"UNIRepeatOptionsView \"repeatOptionSelected\" Delegate not assigned");
    }
}

- (void)layoutSubviews {
    // check to make sure there's not an empty row
    if (self.rows*(self.columns - 1) <= self.options.count) {
        self.rows = 1;
        self.columns = 1;
    }
    
    // check to make sure there's enough space for every option to fit
    while (self.rows * self.columns < self.options.count) {
        if (self.rows < self.columns) {
            self.rows++;
        }
        
        else {
            self.columns++;
        }
    }
    
    // remove all subviews before adding in new buttons
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    // add in buttons
    for (int i = 0; i < self.options.count; i++) {
        [self addSubview:[self repeatOptionButtonForPosition:i]];
    }
}

@end
