//
//  UNIOptionsView.m
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "UNIOptionsView.h"

#define BUTTON_FONT_SIZE 11.0f
#define BUTTON_SPACE 58.0f

@implementation UNIOptionsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.assign];
        [self addSubview:self.share];
        [self addSubview:self.attach];
        [self addSubview:self.event];
    }
    return self;
}

- (UIButton *)assign {
    if (!_assign) {
        _assign = [self buttonWithPosition:0 imageName:@"" title:@"assign"];
        
        [_assign addTarget:self action:@selector(assignButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _assign;
}

- (UIButton *)share {
    if (!_share) {
        _share = [self buttonWithPosition:1 imageName:@"" title:@"share"];
        
        [_share addTarget:self action:@selector(shareButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _share;
}

- (UIButton *)attach {
    if (!_attach) {
        _attach = [self buttonWithPosition:2 imageName:@"" title:@"attach"];
        
        [_attach addTarget:self action:@selector(attachButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _attach;
}

- (UIButton *)event {
    if (!_event) {
        _event = [self buttonWithPosition:3 imageName:@"" title:@"event"];
        
        [_event addTarget:self action:@selector(eventButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _event;
}


- (UIButton *)buttonWithPosition:(int)position imageName:(NSString *)imageName title:(NSString *)title {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(75.0f + position * BUTTON_SPACE, 0, self.frame.size.width/5, self.frame.size.height)];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:button.frame];
    UIImage *image = [UIImage imageNamed:imageName];
    [imageView setImage:image];
    [button addSubview:imageView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height/3 - 2.5f, button.frame.size.width, self.frame.size.height)];
    [label setText:title];
    [label setFont:[UIFont systemFontOfSize:BUTTON_FONT_SIZE]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor darkTextColor]];
    [button addSubview:label];
    
    return button;
}

#pragma mark - Delegate Methods

- (void)assignButtonTouched {
    if ([self.delegate respondsToSelector:@selector(assignButtonTouched)]) {
        [self.delegate assignButtonTouched];
    }
    
    else {
        NSLog(@"UNIOptionsView \"assignButtonTouched\" delegate method not assigned");
    }
}

- (void)shareButtonTouched {
    if ([self.delegate respondsToSelector:@selector(shareButtonTouched)]) {
        [self.delegate shareButtonTouched];
    }
    
    else {
        NSLog(@"UNIOptionsView \"shareButtonTouched\" delegate method not assigned");
    }
}

- (void)attachButtonTouched {
    if ([self.delegate respondsToSelector:@selector(attachButtonTouched)]) {
        [self.delegate attachButtonTouched];
    }
    
    else {
        NSLog(@"UNIOptionsView \"attachButtonTouched\" delegate method not assigned");
    }
}

- (void)eventButtonTouched {
    if ([self.delegate respondsToSelector:@selector(eventButtonTouched)]) {
        [self.delegate eventButtonTouched];
    }
    
    else {
        NSLog(@"UNIOptionsView \"eventButtonTouched\" delegate method not assigned");
    }
}

@end
