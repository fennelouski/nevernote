//
//  UNIAdditionalOptionsView.h
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UNIAdditionalOptionsViewButton.h"
#import "UNITimeInputView.h"
#import "UNIRepeatOptionsView.h"

@protocol UNIAdditionalOptionsViewDelegate <NSObject>

@required
- (void)switchView;
- (void)accountButtonTouched;
- (void)alarmButtonTouched;
- (void)repeatButtonTouched;

- (void)repeatOptionSelected:(NSString *)option;
- (void)alarmTimeSelected:(NSDate *)alarmTime;

@end

@interface UNIAdditionalOptionsView : UIView <UNITimeInputViewDelegate, UNIRepeatOptionsViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate>

- (instancetype)initWithAccountCount:(int)numberOfAccounts;

@property (nonatomic) BOOL isSmall, isAnimating, hasAccountButton, alarmEnabled, repeatEnabled, alarmShowing, repeatShowing;
@property (nonatomic, strong) UNIAdditionalOptionsViewButton *accountButton, *alarmButton, *repeatButton;
@property (nonatomic, strong) UILabel *accountLabel, *alarmLabel, *repeatLabel;
@property (nonatomic, weak) id <UNIAdditionalOptionsViewDelegate> delegate;
@property (nonatomic, strong) UIView *background;
@property (nonatomic) CGRect smallFrame, largeFrame;
@property (nonatomic, strong) UIColor *greyColor, *accountColor, *smallSizeBackgroundColor;
@property (nonatomic, strong) UNIRepeatOptionsView *repeatOptionsView;

@property (nonatomic, strong) UIToolbar *timeInputToolbar;
@property (nonatomic, strong) UITextField *timeInputTextField;
@property (nonatomic, strong) UNITimeInputView *timeInputView;

- (void)switchView;
- (void)accountButtonTouched;
- (void)alarmButtonTouched;
- (void)repeatButtonTouched;

- (void)repeatOptionSelected:(NSString *)option;
- (void)alarmTimeSelected:(NSDate *)alarmTime;

@end
