//
//  UNICalendarPopOver.m
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "UNICalendarPopOver.h"

// Dimensions
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@implementation UNICalendarPopOver

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self setFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
        [self addSubview:self.blur];
        [self addGestureRecognizer:self.swipe];
        [self addSubview:self.closeButton];
        [self setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.3f]];
    }
    
    return self;
}

- (UISwipeGestureRecognizer *)swipe {
    if (!_swipe) {
        _swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(removeCalendarPopOver)];
        [_swipe setDirection:UISwipeGestureRecognizerDirectionRight];
    }
    
    return _swipe;
}

- (UIToolbar *)blur {
    if (!_blur) {
        _blur = [[UIToolbar alloc] initWithFrame:self.frame];
        [_blur setBarStyle:UIBarStyleBlackTranslucent];
        [_blur setTintColor:[UIColor blackColor]];
    }
    
    return _blur;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_closeButton setImage:[UIImage imageNamed:@"pull-close"] forState:UIControlStateNormal];
        [_closeButton sizeToFit];
        [_closeButton setCenter:CGPointMake(kScreenWidth - _closeButton.frame.size.width/2, _closeButton.frame.size.height/2)];
        [_closeButton addTarget:self action:@selector(removeCalendarPopOver) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton addTarget:self action:@selector(removeCalendarPopOver) forControlEvents:UIControlEventTouchDragInside];
    }
    
    return _closeButton;
}

- (void)removeCalendarPopOver {
    if ([self.delegate respondsToSelector:@selector(removeCalendarPopOver)]) {
        [self.delegate removeCalendarPopOver];
    }
}

@end
