//
//  UNISuggestionView.m
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "UNISuggestionView.h"
#import "UIColor+AppColors.h"

// Dimensions
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height


//Dimensions
#define SUGGESTION_VIEW_HEIGHT_MAX kScreenHeight/2
#define SUGGESTION_VIEW_WIDTH 150.0f

@implementation UNISuggestionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.layer setCornerRadius:10.0f];
        [self setBackgroundColor:[UIColor blueAppColor]];
        [self addSubview:self.scrollView];
        [self setClipsToBounds:YES];
    }
    
    return self;
}

- (instancetype)initWithPoint:(CGPoint)point {
    self = [self initWithFrame:CGRectMake(point.x - SUGGESTION_VIEW_WIDTH/2, point.y + 10.0f, SUGGESTION_VIEW_WIDTH, self.textSize)];
    
    if (self) {
        self.anchor = point;
        self.isUp = (self.anchor.y > kScreenHeight/2) ? YES : NO;
        self.interval = 3;
    }
    
    return self;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    }
    
    return _scrollView;
}

- (void)layoutSubviews {
    
    float yPosition = self.textSize*self.interval;
    
    for (NSString *string in self.suggestions) {
        UIView *cell = [self cell:string];
        [cell setCenter:CGPointMake(self.frame.size.width/2, yPosition)];
        
        [self.scrollView addSubview:cell];
        yPosition += self.textSize*self.interval;
    }
    
    yPosition -= self.textSize*self.interval;
    
    [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, (yPosition > SUGGESTION_VIEW_HEIGHT_MAX) ? SUGGESTION_VIEW_HEIGHT_MAX : yPosition)];
    [self.scrollView setFrame:self.frame];
    [self.scrollView setCenter:CGPointMake(self.frame.size.width/2, self.frame.size.height/2)];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width, yPosition)];
}

- (UIView *)cell:(NSString *)text {
    UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.textSize*self.interval)];
    
    UIButton *button = [[UIButton alloc] initWithFrame:cell.frame];
    [button setCenter:CGPointMake(button.center.x, 0)];
    [button setTitle:text forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:self.textSize]];
    [button addTarget:self action:@selector(suggestionSelected:) forControlEvents:UIControlEventTouchUpInside];
    [cell addSubview:button];
    
    UIView *border = [[UIView alloc] initWithFrame:CGRectMake(5.0f, -self.textSize*self.interval/2, cell.frame.size.width - 10.0f, 0.5f)];
    [border setBackgroundColor:[UIColor separatorColor]];
    [cell addSubview:border];
    
    return cell;
}

- (void)suggestionSelected:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(suggestionSelected:)]) {
        [self.delegate suggestionSelected:button];
    }
    
    else {
        NSLog(@"UNISuggestionView \"suggestionSelected\" delegate not assigned");
    }
}

@end
