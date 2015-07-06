//
//  UNIAdditionalOptionsViewButton.m
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "UNIAdditionalOptionsViewButton.h"
#import "UIColor+AppColors.h"

@implementation UNIAdditionalOptionsViewButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.smallLabelCenter = CGPointMake(self.frame.size.width * 3, self.frame.size.height*2/3);
    }
    return self;
}

@end
