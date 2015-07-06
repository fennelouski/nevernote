//
//  UNIOptionsView.h
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UNIOptionsViewDelegate <NSObject>

@required
- (void)assignButtonTouched;
- (void)shareButtonTouched;
- (void)attachButtonTouched;
- (void)eventButtonTouched;

@end


@interface UNIOptionsView : UIView

@property (nonatomic, strong) UIButton *assign, *share, *attach, *event;
@property (nonatomic, weak) id <UNIOptionsViewDelegate> delegate;

- (void)assignButtonTouched;
- (void)shareButtonTouched;
- (void)attachButtonTouched;
- (void)eventButtonTouched;

@end
