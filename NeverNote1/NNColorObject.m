//
//  NNColorObject.m
//  NeverNote
//
//  Created by Nathan Fennel on 7/2/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "NNColorObject.h"

@implementation NNColorObject

- (instancetype)init {
    self = [super init];
    
    if (self) {
        
    }
    
    return self;
}

- (void)updateHex {
    [self colorFromHex];
    
    [self hsvFromRgb];
}

// takes @"#123456"
- (void)colorFromHex {
    const char *cStr = [self.hexValue cStringUsingEncoding:NSASCIIStringEncoding];
    long x = strtol(cStr+1, NULL, 16);
    [self colorWithHex:x];
}

// takes 0x123456
- (void)colorWithHex:(UInt32)col {
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    
    self.red = r/255.0f;
    self.green = g/255.0f;
    self.blue = b/255.0f;
    
    [self setColor:[UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1]];
    
    
}

- (void)hsvFromRgb {
    CGFloat min, max, delta;
    
    NSNumber *r = [NSNumber numberWithFloat:self.red];
    NSNumber *g = [NSNumber numberWithFloat:self.green];
    NSNumber *b = [NSNumber numberWithFloat:self.blue];
    
    min = [self minValueInArray:[NSArray arrayWithObjects:r, g, b, nil] withIndex:NULL];
    max = [self maxValueInArray:[NSArray arrayWithObjects:r, g, b, nil] withIndex:NULL];
    delta = max - min;
    
    self.brightness = max;
    
    if (max != 0) {
        self.saturation = delta/max;
    } else {
        // r = g = b = 0, thus s = 0, v = undefined.
        self.saturation = 0;
        self.hue = 0;
        self.brightness = 0;
    }
    
    if (delta != 0) { // To avoid division-by-zero error.
        if (self.red == max) {
            self.hue = (self.green - self.blue) / delta;        // Between yellow and magenta.
        } else if (self.green == max) {
            self.hue = 2 + (self.blue - self.red) / delta;    // Between cyan and yellow.
        } else {
            self.hue = 4 + (self.red - self.green) / delta;    // Between magenta and cyan.
        }
        self.hue *= 60.0f; // Degrees.
        if (self.hue < 0) {
            self.hue += 360.0f;
        }
    } else {
        self.hue = 0;
    }
    
    self.hue /= 360.0f;
}

- (CGFloat)minValueInArray:(NSArray *)arr withIndex:(NSInteger *)outIndex {
    CGFloat min = -MAXFLOAT;
    if ([arr count] > 0) {
        min = [[arr objectAtIndex:0] floatValue];
        for (NSInteger i=0; i<[arr count]; i++) {
            if ([[arr objectAtIndex:i] floatValue] < min) {
                min = [[arr objectAtIndex:i] floatValue];
                if (outIndex != NULL) {
                    *outIndex = i;
                }
            }
        }
    }
    return min;
}

- (CGFloat)maxValueInArray:(NSArray *)arr withIndex:(NSInteger *)outIndex {
    CGFloat max = -1;
    if ([arr count] > 0) {
        max = [[arr objectAtIndex:0] floatValue];
        for (NSInteger i=0; i<[arr count]; i++) {
            if ([[arr objectAtIndex:i] floatValue] > max) {
                max = [[arr objectAtIndex:i] floatValue];
                if (outIndex != NULL) {
                    *outIndex = i;
                }
            }
        }
    }
    return max;
}

@end
