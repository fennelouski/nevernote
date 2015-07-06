//
//  UNICalendarPopOver.h
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UNICalendarPopOverDelegate <NSObject>

@required
- (void)dateSelected:(UIButton *)button;
- (void)removeCalendarPopOver;

@end

@interface UNICalendarPopOver : UIView

@property (nonatomic, strong) UISwipeGestureRecognizer *swipe;
@property (nonatomic, strong) UIToolbar *blur;
@property (nonatomic, weak) id <UNICalendarPopOverDelegate> delegate;
@property (nonatomic, strong) UIButton *closeButton;

- (void)removeCalendarPopOver;

@end
