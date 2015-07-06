//
//  UNITimeInputView.h
//  Donebox
//
//  Created by Nathan Fennel on 7/6/14.
//  Copyright (c) 2014 Troy Chmieleski. All rights reserved.
//
// Input View (keyboard replacement) intended for time input
// Not intended for 24 hour clocks

#import <UIKit/UIKit.h>

@protocol UNITimeInputViewDelegate <NSObject>

@required
- (void)timeInputViewOutput:(NSString *)output;
- (void)closeTimeInputView;

@end

@interface UNITimeInputView : UIView

@property (nonatomic, strong) NSMutableArray *hours, *minutes, *ampm;
@property (nonatomic) int rows, columns;
@property (nonatomic, strong) UIView *hourView, *minuteView;
@property (nonatomic) BOOL hourSet;
@property (nonatomic, weak) id <UNITimeInputViewDelegate> delegate;

- (void)timeInputViewOutput:(NSString *)output;
- (void)closeTimeInputView;
- (void)resetTimeInputView;

@end
