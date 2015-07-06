//
//  UNIAdditionalOptionsViewButton.h
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UNIAdditionalOptionsViewButton : UIButton

@property (nonatomic, strong) UILabel *label;
@property (nonatomic) CGRect smallFrame, largeFrame;
@property (nonatomic) CGPoint smallLabelCenter, largeLabelCenter;

@end
