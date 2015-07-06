//
//  UNIRepeatOptionsView.h
//  NeverNote
//
//  Created by Nathan Fennel on 7/7/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UNIRepeatOptionsViewDelegate <NSObject>

@required
- (void)repeatOptionSelected:(NSString *)option;

@end

@interface UNIRepeatOptionsView : UIView

@property (nonatomic) int rows, columns;
@property (nonatomic, strong) NSMutableArray *options;
@property (nonatomic, weak) id <UNIRepeatOptionsViewDelegate> delegate;
@property (nonatomic) CGPoint displayCenter, hiddenCenter;

- (void) repeatOptionViewManuallyTouched:(UITouch *)touch;

@end
