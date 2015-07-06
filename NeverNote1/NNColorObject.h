//
//  NNColorObject.h
//  NeverNote
//
//  Created by Nathan Fennel on 7/2/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNColorObject : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic) float red, green, blue;
@property (nonatomic) float hue, saturation, brightness;
@property (nonatomic, strong) NSString *hexValue;
@property (nonatomic, strong) UIColor *color;


- (void)updateHex;

@end
