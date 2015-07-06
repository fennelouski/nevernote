//
//  UNISuggestionView.h
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UNISuggestionViewDelegate <NSObject>

@required
- (void)suggestionSelected:(UIButton *)button;

@end

@interface UNISuggestionView : UIView

- (instancetype)initWithPoint:(CGPoint)point;

@property (nonatomic, strong) NSMutableArray *suggestions;
@property (nonatomic) float textSize;
@property (nonatomic) int interval;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic) BOOL isUp;
@property (nonatomic) CGPoint anchor;
@property (nonatomic, weak) id <UNISuggestionViewDelegate> delegate;

- (void)suggestionSelected:(UIButton *)button;

@end
