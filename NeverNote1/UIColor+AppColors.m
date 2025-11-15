//
//  UIColor+AppColors.m
//  NeverNote
//
//  Created by Nathan Fennel on 6/10/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "UIColor+AppColors.h"

@implementation UIColor (AppColors)

+ (UIColor *)colorWithHexString:(NSString *)str {
    const char *cStr = [str cStringUsingEncoding:NSASCIIStringEncoding];
    long x = strtol(cStr+1, NULL, 16);
    return [UIColor colorWithHex:x];
}

+ (UIColor *)colorWithHex:(UInt32)col {
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

#pragma mark - App icon

+ (UIColor *)appIconBlueColor {
	return [UIColor colorWithRed:42.0/255.0 green:163.0/255.0 blue:218.0/255.0 alpha:1.0];
}

#pragma mark - App colors

+ (UIColor *)mediumGrayAppColor {
    return [UIColor colorWithRed:122/255.0f green:122/255.0f blue:122/255.0f alpha:1.0f];
}

+ (UIColor *)blueAppColor{
    return [UIColor colorWithRed:0/255.0f green:122/255.0f blue:255/255.0f alpha:1.0f];
}

+ (UIColor *)lightGrayAppColor {
    return [UIColor colorWithRed:204/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f];
}

+ (UIColor *)darkGrayAppColor {
    return [UIColor colorWithRed:50/255.0f green:50/255.0f blue:50/255.0f alpha:1.0f];
}

+ (UIColor *)grayBackgroundAppColor {
    return [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
}

+ (UIColor *)redAppColor {
	return [UIColor colorWithRed:255/255.0f green:10/255.0f blue:10/255.0f alpha:1.0f];
}

#pragma mark - Inbox

+ (UIColor *)inboxBackgroundColor {
	return [UIColor inboxEmailCellUnreadBackgroundColor];
}

#pragma mark - App account colors

+ (UIColor *)appAccountPurpleColor {
	return [UIColor colorWithRed:161.0/255.0 green:134.0/255.0 blue:190.0/255.0 alpha:1.0];
}

#pragma mark - Inbox email cell colors

+ (UIColor *)inboxEmailCellUnreadBackgroundColor {
	return [UIColor whiteColor];
}

+ (UIColor *)inboxEmailCellReadBackgroundColor {
	return [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
}

+ (UIColor *)inboxEmailCellUnreadTimeLabelTextColor {
	return [UIColor blackColor];
}

+ (UIColor *)inboxEmailCellReadTimeLabelTextColor {
	return [UIColor colorWithWhite:0.6 alpha:1.0];
}

+ (UIColor *)inboxEmailCellUnreadReadUnreadNamesLabelTextColor {
	return [UIColor colorWithWhite:0.4 alpha:1.0];
}

+ (UIColor *)inboxEmailCellReadReadUnreadNamesLabelTextColor {
	return [UIColor colorWithWhite:0.4 alpha:1.0];
}

+ (UIColor *)inboxEmailCellUnreadMessagePreviewTextColor {
	return [UIColor colorWithWhite:0.4 alpha:1.0];
}

+ (UIColor *)inboxEmailCellReadMessagePreviewTextColor {
	return [UIColor colorWithWhite:0.4 alpha:1.0];
}

+ (UIColor *)inboxEmailCellUnreadIndicatorColor {
	return [UIColor colorWithRed:0.0 green:122.0f/255.0 blue:1.0 alpha:1.0];
}

+ (UIColor *)inboxEmailCellUnreadTotalTextColor {
	return [UIColor colorWithWhite:0.4 alpha:1.0];
}

+ (UIColor *)inboxEmailCellHighlightedColor {
	return [UIColor colorWithWhite:0.9 alpha:1.0];
}

#pragma mark - Conversation background color

+ (UIColor *)conversationBackgroundColor {
	return [UIColor colorWithRed:229.0/255.0 green:229.0/255.0 blue:229.0/255.0 alpha:1.0];
}

+ (UIColor *)conversationViewUnreadBackgroundColor {
	return [self inboxEmailCellUnreadBackgroundColor];
}

+ (UIColor *)conversationViewReadBackgroundColor {
	return [self inboxEmailCellReadBackgroundColor];
}

#pragma mark - Button color

+ (UIColor *)buttonColor {
	return [UIColor appIconBlueColor];
}

#pragma mark - Shade color

+ (UIColor *)shadeColor:(UIColor *)color withMultiple:(CGFloat)multiple {
	if (multiple >= 1.0) {
		return color;
	}
	
	UIColor *shade;
	
	CGFloat red, green, blue, alpha;
	CGFloat redShade, greenShade, blueShade, alphaShade;
	
	BOOL isCompatibleColorSpace = [color getRed:&red green:&green blue:&blue alpha:&alpha];
	
	if (!isCompatibleColorSpace) {
		return color;
	}
	
	redShade = red * multiple;
	greenShade = green * multiple;
	blueShade = blue * multiple;
	alphaShade = alpha;
	
	shade = [UIColor colorWithRed:redShade green:greenShade blue:blueShade alpha:alphaShade];
	
	return shade;
}

#pragma mark - Tint color

+ (UIColor *)tintColor:(UIColor *)color withMultiple:(CGFloat)multiple {
	if (multiple >= 1) {
		return color;
	}
	
	UIColor *tint;
	
	CGFloat red, green, blue, alpha;
	CGFloat redTint, greenTint, blueTint, alphaTint;
	
	BOOL isCompatibleColorSpace = [color getRed:&red green:&green blue:&blue alpha:&alpha];
	
	if (!isCompatibleColorSpace) {
		return color;
	}
	
	redTint = red + MIN(multiple * (1.0f - red), 1.0f);
	greenTint = green + MIN(multiple * (1.0f - green), 1.0f);
	blueTint = blue + MIN(multiple * (1.0f - blue), 1.0f);
	alphaTint = alpha;
	
	tint = [UIColor colorWithRed:redTint green:greenTint blue:blueTint alpha:alphaTint];
	
	return tint;
}

#pragma mark - Keyboard colors

+ (UIColor *)lightKeyboardBackgroundColor {
    return [UIColor colorWithRed:209/255.0f green:213/255.0f blue:219/255.0f alpha:1.0f];
}

+ (UIColor *)lightIphoneKeyboardKeyColor {
    return [UIColor whiteColor];
}

+ (UIColor *)lightNumberPadKeyColor {
    return [UIColor colorWithRed:252/255.0f green:252/255.0f blue:253/255.0f alpha:1.0f];
}

+ (UIColor *)lightNumberPadKeyBorderColor {
    return [UIColor colorWithRed:217/255.0f green:219/255.0f blue:222/255.0f alpha:1.0f];
}

+ (UIColor *)lightNumberPadDarkKeyColor {
    return [UIColor colorWithRed:188/255.0f green:192/255.0f blue:196/255.0f alpha:1.0f];
}

+ (UIColor *)lightNumberPadSelectedKeyColor {
    return [UIColor colorWithRed:188/255.0f green:191/255.0f blue:196/255.0f alpha:1.0f];
}

#pragma mark - Image with Color

/**
 *  Creates UIImage from color
 *
 *  @param color Color for the entire image
 *
 *  @return UIImage of just the color
 */
+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIColor *)randomPastelColor {
    return [UIColor colorWithHue:arc4random()%255/255.0f saturation:(arc4random()%200 + 55)/255.0f brightness:((arc4random()%200) + 55.0f)/255.0f alpha:1.0f];
}

#pragma mark - Semantic Colors for Dark Mode Support

// Background Colors
+ (UIColor *)systemBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]; // Black
            } else {
                return [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0]; // White
            }
        }];
    } else {
        return [UIColor whiteColor];
    }
}

+ (UIColor *)secondarySystemBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:28/255.0 green:28/255.0 blue:30/255.0 alpha:1.0]; // Dark gray
            } else {
                return [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1.0]; // Light gray
            }
        }];
    } else {
        return [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1.0];
    }
}

+ (UIColor *)tertiarySystemBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:44/255.0 green:44/255.0 blue:46/255.0 alpha:1.0]; // Medium dark gray
            } else {
                return [UIColor whiteColor];
            }
        }];
    } else {
        return [UIColor whiteColor];
    }
}

// Text Colors
+ (UIColor *)labelColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor whiteColor];
            } else {
                return [UIColor blackColor];
            }
        }];
    } else {
        return [UIColor blackColor];
    }
}

+ (UIColor *)secondaryLabelColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:0.92 alpha:0.6];
            } else {
                return [UIColor colorWithWhite:0.4 alpha:1.0];
            }
        }];
    } else {
        return [UIColor colorWithWhite:0.4 alpha:1.0];
    }
}

+ (UIColor *)tertiaryLabelColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:0.92 alpha:0.3];
            } else {
                return [UIColor colorWithWhite:0.6 alpha:1.0];
            }
        }];
    } else {
        return [UIColor colorWithWhite:0.6 alpha:1.0];
    }
}

// Separator Colors
+ (UIColor *)separatorColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:1.0 alpha:0.2];
            } else {
                return [UIColor colorWithWhite:0.0 alpha:0.2];
            }
        }];
    } else {
        return [UIColor colorWithWhite:0.0 alpha:0.2];
    }
}

+ (UIColor *)opaqueSeparatorColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:56/255.0 green:56/255.0 blue:58/255.0 alpha:1.0];
            } else {
                return [UIColor colorWithRed:198/255.0 green:198/255.0 blue:200/255.0 alpha:1.0];
            }
        }];
    } else {
        return [UIColor colorWithRed:198/255.0 green:198/255.0 blue:200/255.0 alpha:1.0];
    }
}

// Keyboard Colors (Dark Mode Adaptive)
+ (UIColor *)keyboardBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
            } else {
                return [UIColor colorWithRed:209/255.0 green:213/255.0 blue:219/255.0 alpha:1.0];
            }
        }];
    } else {
        return [UIColor colorWithRed:209/255.0 green:213/255.0 blue:219/255.0 alpha:1.0];
    }
}

+ (UIColor *)keyboardKeyColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:76/255.0 green:76/255.0 blue:78/255.0 alpha:1.0];
            } else {
                return [UIColor whiteColor];
            }
        }];
    } else {
        return [UIColor whiteColor];
    }
}

+ (UIColor *)numberPadKeyColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:76/255.0 green:76/255.0 blue:78/255.0 alpha:1.0];
            } else {
                return [UIColor colorWithRed:252/255.0 green:252/255.0 blue:253/255.0 alpha:1.0];
            }
        }];
    } else {
        return [UIColor colorWithRed:252/255.0 green:252/255.0 blue:253/255.0 alpha:1.0];
    }
}

+ (UIColor *)numberPadKeyBorderColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:56/255.0 green:56/255.0 blue:58/255.0 alpha:1.0];
            } else {
                return [UIColor colorWithRed:217/255.0 green:219/255.0 blue:222/255.0 alpha:1.0];
            }
        }];
    } else {
        return [UIColor colorWithRed:217/255.0 green:219/255.0 blue:222/255.0 alpha:1.0];
    }
}

+ (UIColor *)numberPadDarkKeyColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:98/255.0 green:98/255.0 blue:102/255.0 alpha:1.0];
            } else {
                return [UIColor colorWithRed:188/255.0 green:192/255.0 blue:196/255.0 alpha:1.0];
            }
        }];
    } else {
        return [UIColor colorWithRed:188/255.0 green:192/255.0 blue:196/255.0 alpha:1.0];
    }
}

+ (UIColor *)numberPadSelectedKeyColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:98/255.0 green:98/255.0 blue:102/255.0 alpha:1.0];
            } else {
                return [UIColor colorWithRed:188/255.0 green:191/255.0 blue:196/255.0 alpha:1.0];
            }
        }];
    } else {
        return [UIColor colorWithRed:188/255.0 green:191/255.0 blue:196/255.0 alpha:1.0];
    }
}

// Colors that should have been there from the beginning
+ (UIColor *)acidGreen {
    return [UIColor colorWithRed:0.69f green:0.75f blue:0.10f alpha:1.0f];
}

+ (UIColor *)aero {
    return [UIColor colorWithRed:0.49f green:0.73f blue:0.91f alpha:1.0f];
}

+ (UIColor *)aeroBlue {
    return [UIColor colorWithRed:0.79f green:1.0f blue:0.90f alpha:1.0f];
}

+ (UIColor *)africanViolet {
    return [UIColor colorWithRed:0.70f green:0.52f blue:0.75f alpha:1.0f];
}

+ (UIColor *)airForceBlueRAF {
    return [UIColor colorWithRed:0.36f green:0.54f blue:0.66f alpha:1.0f];
}

+ (UIColor *)airForceBlue {
    return [UIColor colorWithRed:0.0f green:0.19f blue:0.56f alpha:1.0f];
}

+ (UIColor *)airSuperiorityBlue {
    return [UIColor colorWithRed:0.45f green:0.63f blue:0.76f alpha:1.0f];
}

+ (UIColor *)alabamaCrimson {
    return [UIColor colorWithRed:0.69f green:0.0f blue:0.16f alpha:1.0f];
}

+ (UIColor *)aliceBlue {
    return [UIColor colorWithRed:0.94f green:0.97f blue:1.0f alpha:1.0f];
}

+ (UIColor *)alizarinCrimson {
    return [UIColor colorWithRed:0.89f green:0.15f blue:0.21f alpha:1.0f];
}

+ (UIColor *)alloyOrange {
    return [UIColor colorWithRed:0.77f green:0.38f blue:0.06f alpha:1.0f];
}

+ (UIColor *)almond {
    return [UIColor colorWithRed:0.94f green:0.87f blue:0.80f alpha:1.0f];
}

+ (UIColor *)amaranth {
    return [UIColor colorWithRed:0.9f green:0.17f blue:0.31f alpha:1.0f];
}

+ (UIColor *)amaranthPink {
    return [UIColor colorWithRed:0.95f green:0.61f blue:0.73f alpha:1.0f];
}

+ (UIColor *)amaranthPurple {
    return [UIColor colorWithRed:0.67f green:0.15f blue:0.31f alpha:1.0f];
}

+ (UIColor *)amaranthRed {
    return [UIColor colorWithRed:0.83f green:0.13f blue:0.18f alpha:1.0f];
}

+ (UIColor *)amazon {
    return [UIColor colorWithRed:0.23f green:0.48f blue:0.34f alpha:1.0f];
}

+ (UIColor *)amber {
    return [UIColor colorWithRed:1.0f green:0.75 blue:0.0f alpha:1.0f];
}

+ (UIColor *)amberSAE {
    return [UIColor colorWithRed:1.0f green:0.49f blue:0.0f alpha:1.0f];
}

+ (UIColor *)americanRose {
    return [UIColor colorWithRed:1.0f green:0.01f blue:0.24f alpha:1.0f];
}

+ (UIColor *)amethyst {
    return [UIColor colorWithRed:0.60f green:0.40f blue:0.80f alpha:1.0f];
}

+ (UIColor *)androidGreen {
    return [UIColor colorWithRed:0.64f green:0.78f blue:0.22f alpha:1.0f];
}

+ (UIColor *)antiFlashWhite {
    return [UIColor colorWithRed:0.95f green:0.95f blue:0.96 alpha:1.0f];
}


+ (UIColor *)antiqueBrass {
    return [UIColor colorWithRed:0.80f green:0.58f blue:0.46f alpha:1.0f];
}

+ (UIColor *)antiqueBronze {
    return [UIColor colorWithRed:0.40f green:0.36f blue:0.12f alpha:1.0f];
}

+ (UIColor *)antiqueFuchsia {
    return [UIColor colorWithRed:0.57f green:0.36f blue:0.51f alpha:1.0f];
}

+ (UIColor *)antiqueRuby {
    return [UIColor colorWithRed:0.52f green:0.11f blue:0.18f alpha:1.0f];
}

+ (UIColor *)antiqueWhite {
    return [UIColor colorWithRed:0.98f green:0.92f blue:0.84f alpha:1.0f];
}

+ (UIColor *)ao {
    return [UIColor colorWithRed:0.0f green:0.50f blue:0.0f alpha:1.0f];
}

+ (UIColor *)appleGreen {
    return [UIColor colorWithRed:0.55f green:0.71f blue:0.0f alpha:1.0f];
}

+ (UIColor *)apricot {
    return [UIColor colorWithRed:0.98f green:0.81f blue:0.69f alpha:1.0f];
}

+ (UIColor *)aqua {
    return [UIColor colorWithRed:0.0f green:1.0f blue:1.0f alpha:1.0f];
}

+ (UIColor *)aquamarine {
    return [UIColor colorWithRed:0.50f green:1.0f blue:0.83f alpha:1.0f];
}

+ (UIColor *)armyGreen {
    return [UIColor colorWithRed:0.29f green:0.33f blue:0.13f alpha:1.0f];
}

+ (UIColor *)arsenic {
    return [UIColor colorWithRed:0.23f green:0.27f blue:0.29f alpha:1.0f];
}

+ (UIColor *)artichoke {
    return [UIColor colorWithRed:0.56f green:0.59f blue:0.47f alpha:1.0f];
}

+ (UIColor *)arylideYellow {
    return [UIColor colorWithRed:0.91f green:0.84f blue:0.42f alpha:1.0f];
}

+ (UIColor *)ashGrey {
    return [UIColor colorWithRed:0.70f green:0.75f blue:0.71f alpha:1.0f];
}

+ (UIColor *)asparagus {
    return [UIColor colorWithRed:0.53f green:0.66f blue:0.42f alpha:1.0f];
}

+ (UIColor *)atomicTangerine {
    return [UIColor colorWithRed:1.0f green:0.6f blue:0.4f alpha:1.0f];
}

+ (UIColor *)auburn {
    return [UIColor colorWithRed:0.65f green:0.16f blue:0.16f alpha:1.0f];
}

+ (UIColor *)aureolin {
    return [UIColor colorWithRed:0.99f green:0.93f blue:0.0f alpha:1.0f];
}

+ (UIColor *)auroMetalSaurus {
    return [UIColor colorWithRed:0.43f green:0.5f blue:0.5f alpha:1.0f];
}

+ (UIColor *)avocado {
    return [UIColor colorWithRed:0.34f green:0.51f blue:0.01f alpha:1.0f];
}

+ (UIColor *)azure {
    return [UIColor colorWithRed:0.0f green:0.5f blue:1.0f alpha:1.0f];
}

+ (UIColor *)azureWebColor {
    return [UIColor colorWithRed:0.94f green:1.0f blue:1.0f alpha:1.0f];
}

+ (UIColor *)azureMist {
    return [self azureWebColor];
}

+ (UIColor *)azureWhite {
    return [UIColor colorWithRed:0.86f green:0.91f blue:0.96f alpha:1.0f];
}

+ (UIColor *)babyBlue {
    return [UIColor colorWithRed:0.54f green:0.81f blue:0.94f alpha:1.0f];
}

+ (UIColor *)babyBlueEyes {
    return [UIColor colorWithRed:0.63f green:0.79f blue:0.95f alpha:1.0f];
}

+ (UIColor *)babyPink {
    return [UIColor colorWithRed:0.96f green:0.76f blue:0.76f alpha:1.0f];
}

+ (UIColor *)babyPowder {
    return [UIColor colorWithRed:1.0f green:1.0f blue:0.98f alpha:1.0f];
}

+ (UIColor *)bakerMillerPink {
    return [UIColor colorWithRed:1.0f green:0.57f blue:0.69f alpha:1.0f];
}

+ (UIColor *)ballBlue {
    return [UIColor colorWithRed:0.13f green:0.67f blue:0.8f alpha:1.0f];
}

+ (UIColor *)bananaMania {
    return [UIColor colorWithRed:0.98f green:0.91f blue:0.71f alpha:1.0f];
}

+ (UIColor *)bananaYellow {
    return [UIColor colorWithRed:1.0f green:0.88f blue:0.21f alpha:1.0f];
}

+ (UIColor *)bangladeshGreen {
    return [UIColor colorWithRed:0.0f green:0.42f blue:0.31f alpha:1.0f];
}

+ (UIColor *)barbiePink {
    return [UIColor colorWithRed:0.88f green:0.13f blue:0.54f alpha:1.0f];
}

+ (UIColor *)barnRed {
    return [UIColor colorWithRed:0.49f green:0.04f blue:0.01f alpha:1.0f];
}

+ (UIColor *)battleshipGrey {
    return [UIColor colorWithRed:0.52f green:0.52f blue:0.51f alpha:1.0f];
}

+ (UIColor *)bazaar {
    return [UIColor colorWithRed:0.6f green:0.47f blue:0.48f alpha:1.0f];
}

+ (UIColor *)beauBlue {
    return [UIColor colorWithRed:0.74f green:0.83f blue:0.90f alpha:1.0f];
}

+ (UIColor *)beaver {
    return [UIColor colorWithRed:0.62f green:0.51f blue:0.44f alpha:1.0f];
}

+ (UIColor *)beige {
    return [UIColor colorWithRed:0.96f green:0.96f blue:0.86f alpha:1.0f];
}

+ (UIColor *)bdazzledBlue {
    return [UIColor colorWithRed:0.18f green:0.35f blue:0.58f alpha:1.0f];
}

+ (UIColor *)bigDipORuby {
    return [UIColor colorWithRed:0.61f green:0.15f blue:0.26f alpha:1.0f];
}

+ (UIColor *)bisque {
    return [UIColor colorWithRed:1.0f green:0.89f blue:0.77f alpha:1.0f];
}

+ (UIColor *)bistre {
    return [UIColor colorWithRed:0.24f green:0.17f blue:0.12f alpha:1.0f];
}

+ (UIColor *)bistreBrown {
    return [UIColor colorWithRed:0.59f green:0.44f blue:0.09f alpha:1.0f];
}

+ (UIColor *)bitterLemon {
    return [UIColor colorWithRed:0.79f green:0.88f blue:0.05f alpha:1.0f];
}

+ (UIColor *)bitterLime {
    return [UIColor colorWithRed:0.75f green:1.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)bittersweet {
    return [UIColor colorWithRed:1.0f green:0.44f blue:0.37f alpha:1.0f];
}

+ (UIColor *)bittersweetShimmer {
    return [UIColor colorWithRed:0.75f green:0.31f blue:0.32f alpha:1.0f];
}

+ (UIColor *)blackBean {
    return [UIColor colorWithRed:0.24f green:0.05f blue:0.01f alpha:1.0f];
}

+ (UIColor *)blackLeatherJacket {
    return [UIColor colorWithRed:0.15f green:0.21f blue:0.16f alpha:1.0f];
}

+ (UIColor *)blackOlive {
    return [UIColor colorWithRed:0.23f green:0.24f blue:0.21f alpha:1.0f];
}

+ (UIColor *)blanchedAlmond {
    return [UIColor colorWithRed:1.0f green:0.92f blue:0.80f alpha:1.0f];
}

+ (UIColor *)blastOffBronze {
    return [UIColor colorWithRed:0.65f green:0.44f blue:0.39f alpha:1.0f];
}

+ (UIColor *)bleuDeFrance {
    return [UIColor colorWithRed:0.19f green:0.55f blue:0.91f alpha:1.0f];
}

+ (UIColor *)blizzerdBlue {
    return [UIColor colorWithRed:0.67f green:0.90f blue:0.93f alpha:1.0f];
}

+ (UIColor *)blond {
    return [UIColor colorWithRed:0.98f green:0.94f blue:0.75f alpha:1.0f];
}

+ (UIColor *)blueCrayola {
    return [UIColor colorWithRed:0.12f green:0.46f blue:1.0f alpha:1.0f];
}

+ (UIColor *)blueMunsell {
    return [UIColor colorWithRed:0.0f green:0.58f blue:0.69f alpha:1.0f];
}

+ (UIColor *)blueNCS {
    return [UIColor colorWithRed:0.0f green:0.53f blue:0.74f alpha:1.0f];
}

+ (UIColor *)bluePantone {
    return [UIColor colorWithRed:0.0f green:0.09f blue:0.66f alpha:1.0f];
}

+ (UIColor *)bluePigment {
    return [UIColor colorWithRed:0.2f green:0.2f blue:0.6f alpha:1.0f];
}

+ (UIColor *)blueRYB {
    return [UIColor colorWithRed:0.01f green:0.28f blue:1.0f alpha:1.0f];
}

+ (UIColor *)blueBell {
    return [UIColor colorWithRed:0.64f green:0.64f blue:0.82f alpha:1.0f];
}

+ (UIColor *)blueGray {
    return [UIColor colorWithRed:0.40f green:0.60f blue:0.80f alpha:1.0f];
}

+ (UIColor *)blueGreen {
    return [UIColor colorWithRed:0.05f green:0.60f blue:0.73f alpha:1.0f];
}

+ (UIColor *)blueMagentaViolet {
    return [UIColor colorWithRed:0.33f green:0.21f blue:0.57f alpha:1.0f];
}

+ (UIColor *)blueSapphire {
    return [UIColor colorWithRed:0.07f green:0.38f blue:0.50f alpha:1.0f];
}

+ (UIColor *)blueViolet {
    return [UIColor colorWithRed:0.54f green:0.17f blue:0.89f alpha:1.0f];
}

+ (UIColor *)blueYonder {
    return [UIColor colorWithRed:0.31f green:0.45f blue:0.65f alpha:1.0f];
}

+ (UIColor *)blueberry {
    return [UIColor colorWithRed:0.31f green:0.53f blue:0.97f alpha:1.0f];
}

+ (UIColor *)bluebonnet {
    return [UIColor colorWithRed:0.11f green:0.11f blue:0.94f alpha:1.0f];
}

+ (UIColor *)blush {
    return [UIColor colorWithRed:0.87f green:0.36f blue:0.51f alpha:1.0f];
}

+ (UIColor *)bole {
    return [UIColor colorWithRed:0.47f green:0.27f blue:0.23f alpha:1.0f];
}

+ (UIColor *)bondiBlue {
    return [UIColor colorWithRed:0.0f green:0.58f blue:0.71f alpha:1.0f];
}

+ (UIColor *)bone {
    return [UIColor colorWithRed:0.89f green:0.85f blue:0.79f alpha:1.0f];
}

+ (UIColor *)bostonUniversityRed {
    return [UIColor colorWithRed:0.80f green:0.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)bottleGreen {
    return [UIColor colorWithRed:0.0f green:0.42f blue:0.31f alpha:1.0f];
}

+ (UIColor *)boysenberry {
    return [UIColor colorWithRed:0.53f green:0.20f blue:0.38f alpha:1.0f];
}

+ (UIColor *)brandeisBlue {
    return [UIColor colorWithRed:0.0f green:0.44f blue:1.0f alpha:1.0f];
}

+ (UIColor *)brass {
    return [UIColor colorWithRed:0.71f green:0.65f blue:0.26f alpha:1.0f];
}

+ (UIColor *)brickRed {
    return [UIColor colorWithRed:0.80f green:0.25f blue:0.33f alpha:1.0f];
}

+ (UIColor *)brightCerulean {
    return [UIColor colorWithRed:0.11f green:0.67f blue:0.84f alpha:1.0f];
}

+ (UIColor *)brightGreen {
    return [UIColor colorWithRed:0.40f green:1.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)brightLavender {
    return [UIColor colorWithRed:0.75f green:0.58f blue:0.89f alpha:1.0f];
}

+ (UIColor *)brightLilac {
    return [UIColor colorWithRed:0.85f green:0.57f blue:0.94f alpha:1.0f];
}

+ (UIColor *)brightMaroon {
    return [UIColor colorWithRed:0.76f green:0.13f blue:0.28f alpha:1.0f];
}

+ (UIColor *)brightNavyBlue {
    return [UIColor colorWithRed:0.10f green:0.45f blue:0.82f alpha:1.0f];
}

+ (UIColor *)brightPink {
    return [UIColor colorWithRed:1.0f green:0.0f blue:0.5f alpha:1.0f];
}

+ (UIColor *)brightTurquoise {
    return [UIColor colorWithRed:0.03f green:0.91f blue:0.87f alpha:1.0f];
}

+ (UIColor *)brightUbe {
    return [UIColor colorWithRed:0.82f green:0.62f blue:0.91f alpha:1.0f];
}

+ (UIColor *)brilliantAzure {
    return [UIColor colorWithRed:0.20f green:0.60f blue:1.0f alpha:1.0f];
}

+ (UIColor *)brilliantLavender {
    return [UIColor colorWithRed:0.96f green:0.73f blue:1.0f alpha:1.0f];
}

+ (UIColor *)brilliantRose {
    return [UIColor colorWithRed:1.0f green:0.33f blue:0.64f alpha:1.0f];
}

+ (UIColor *)brinkPink {
    return [UIColor colorWithRed:0.98f green:0.38f blue:0.50f alpha:1.0f];
}

+ (UIColor *)britishRacingGreen {
    return [UIColor colorWithRed:0.0f green:0.26f blue:0.15f alpha:1.0f];
}

+ (UIColor *)bronze {
    return [UIColor colorWithRed:0.80f green:0.50f blue:0.20f alpha:1.0f];
}

+ (UIColor *)bronzeYellow {
    return [UIColor colorWithRed:0.45f green:0.27f blue:0.14f alpha:1.0f];
}

+ (UIColor *)brown {
    return [UIColor colorWithRed:0.59f green:0.29f blue:0.0f alpha:1.0f];
}

+ (UIColor *)brownWeb {
    return [UIColor colorWithRed:0.65f green:0.16f blue:0.16f alpha:1.0f];
}

+ (UIColor *)brownNose {
    return [UIColor colorWithRed:0.42f green:0.27f blue:0.14f alpha:1.0f];
}

+ (UIColor *)brunswickGreen {
    return [UIColor colorWithRed:0.11f green:0.30f blue:0.24f alpha:1.0f];
}

+ (UIColor *)bubbleGum {
    return [UIColor colorWithRed:1.0f green:0.76f blue:0.80f alpha:1.0f];
}

+ (UIColor *)bubbles {
    return [UIColor colorWithRed:0.91f green:1.0f blue:1.0f alpha:1.0f];
}

+ (UIColor *)buff {
    return [UIColor colorWithRed:0.94f green:0.86f blue:0.51f alpha:1.0f];
}

+ (UIColor *)budGreen {
    return [UIColor colorWithRed:0.48f green:0.71f blue:0.38f alpha:1.0f];
}

+ (UIColor *)bulgarianRose {
    return [UIColor colorWithRed:0.28f green:0.02f blue:0.03f alpha:1.0f];
}

+ (UIColor *)burgundy {
    return [UIColor colorWithRed:0.50f green:0.0f blue:0.13f alpha:1.0f];
}

+ (UIColor *)burlywood {
    return [UIColor colorWithRed:0.87f green:0.72f blue:0.53f alpha:1.0f];
}

+ (UIColor *)burntOrange {
    return [UIColor colorWithRed:0.80f green:0.33f blue:0.0f alpha:1.0f];
}

+ (UIColor *)burntSienna {
    return [UIColor colorWithRed:0.91f green:0.45f blue:0.32f alpha:1.0f];
}

+ (UIColor *)burntUmber {
    return [UIColor colorWithRed:0.54f green:0.20f blue:0.14f alpha:1.0f];
}

+ (UIColor *)byzantine {
    return [UIColor colorWithRed:0.74f green:0.20f blue:0.64f alpha:1.0f];
}

+ (UIColor *)byzantium {
    return [UIColor colorWithRed:0.44f green:0.16f blue:0.39f alpha:1.0f];
}

+ (UIColor *)cadet {
    return [UIColor colorWithRed:0.33f green:0.41f blue:0.45f alpha:1.0f];
}

+ (UIColor *)cadetBlue {
    return [UIColor colorWithRed:0.37f green:0.62f blue:0.63f alpha:1.0f];
}

+ (UIColor *)cadetGrey {
    return [UIColor colorWithRed:0.57f green:0.64f blue:0.69f alpha:1.0f];
}

+ (UIColor *)cadmiumGreen {
    return [UIColor colorWithRed:0.0f green:0.42f blue:0.24f alpha:1.0f];
}

+ (UIColor *)cadmiumOrange {
    return [UIColor colorWithRed:0.93f green:0.53f blue:0.18f alpha:1.0f];
}

+ (UIColor *)cadmiumRed {
    return [UIColor colorWithRed:0.89f green:0.0f blue:0.13f alpha:1.0f];
}

+ (UIColor *)cadmiumYellow {
    return [UIColor colorWithRed:1.0f green:0.96f blue:0.0f alpha:1.0f];
}

+ (UIColor *)cafeAuLait {
    return [UIColor colorWithRed:0.65f green:0.48f blue:0.36f alpha:1.0f];
}

+ (UIColor *)cafeNoir {
    return [UIColor colorWithRed:0.29f green:0.21f blue:0.13f alpha:1.0f];
}

+ (UIColor *)calPolyPomonaGreen {
    return [UIColor colorWithRed:0.12f green:0.30f blue:0.17f alpha:1.0f];
}

+ (UIColor *)cambridgeBlue {
    return [UIColor colorWithRed:0.64f green:0.76f blue:0.68f alpha:1.0f];
}

+ (UIColor *)camel {
    return [UIColor colorWithRed:0.76f green:0.60f blue:0.42f alpha:1.0f];
}

+ (UIColor *)cameoPink {
    return [UIColor colorWithRed:0.94f green:0.73f blue:0.80f alpha:1.0f];
}

+ (UIColor *)camouflageGreen {
    return [UIColor colorWithRed:0.47f green:0.53f blue:0.42f alpha:1.0f];
}

+ (UIColor *)canaryYellow {
    return [UIColor colorWithRed:1.0f green:0.94f blue:0.0f alpha:1.0f];
}

+ (UIColor *)candyAppleRed {
    return [UIColor colorWithRed:1.0f green:0.03f blue:0.0f alpha:1.0f];
}

+ (UIColor *)candyPink {
    return [UIColor colorWithRed:0.89f green:0.44f blue:0.48f alpha:1.0f];
}

+ (UIColor *)capri {
    return [UIColor colorWithRed:0.0f green:0.75f blue:1.0f alpha:1.0f];
}

+ (UIColor *)caputMortuum {
    return [UIColor colorWithRed:0.35f green:0.15f blue:0.13f alpha:1.0f];
}

+ (UIColor *)cardinal {
    return [UIColor colorWithRed:0.77f green:0.12f blue:0.23f alpha:1.0f];
}

+ (UIColor *)caribbeanGreen {
    return [UIColor colorWithRed:0.0f green:0.8f blue:0.6f alpha:1.0f];
}

+ (UIColor *)carmine {
    return [UIColor colorWithRed:0.59f green:0.0f blue:0.09f alpha:1.0f];
}

+ (UIColor *)carmineMP {
    return [UIColor colorWithRed:0.84f green:0.0f blue:0.25f alpha:1.0f];
}

+ (UIColor *)carminePink {
    return [UIColor colorWithRed:0.92f green:0.3f blue:0.26f alpha:1.0f];
}

+ (UIColor *)carmineRed {
    return [UIColor colorWithRed:1.0f green:0.0f blue:0.22f alpha:1.0f];
}

+ (UIColor *)carnationPink {
    return [UIColor colorWithRed:1.0f green:0.65f blue:0.79f alpha:1.0f];
}

+ (UIColor *)carnelian {
    return [UIColor colorWithRed:0.70f green:0.11f blue:0.11f alpha:1.0f];
}

+ (UIColor *)carolinBlue {
    return [UIColor colorWithRed:0.34f green:0.63f blue:0.83f alpha:1.0f];
}

+ (UIColor *)carrotOrange {
    return [UIColor colorWithRed:0.93f green:0.57f blue:0.13f alpha:1.0f];
}

+ (UIColor *)castletonGreen {
    return [UIColor colorWithRed:0.0f green:0.34f blue:0.25f alpha:1.0f];
}

+ (UIColor *)catalinaBlue {
    return [UIColor colorWithRed:0.02f green:0.16f blue:0.47f alpha:1.0f];
}

+ (UIColor *)catawba {
    return [UIColor colorWithRed:0.44f green:0.21f blue:0.26f alpha:1.0f];
}

+ (UIColor *)cedarChest {
    return [UIColor colorWithRed:0.44f green:0.21f blue:0.26f alpha:1.0f];
}

+ (UIColor *)ceil {
    return [UIColor colorWithRed:0.79f green:0.35f blue:0.29f alpha:1.0f];
}

+ (UIColor *)celadon {
    return [UIColor colorWithRed:0.67f green:0.88f blue:0.69f alpha:1.0f];
}

+ (UIColor *)celadonBlue {
    return [UIColor colorWithRed:0.29f green:0.59f blue:0.82f alpha:1.0f];
}

+ (UIColor *)celadonGreen {
    return [UIColor colorWithRed:0.18f green:0.52f blue:0.49f alpha:1.0f];
}

+ (UIColor *)celeste {
    return [UIColor colorWithRed:0.70f green:1.0f blue:1.0f alpha:1.0f];
}

+ (UIColor *)celestialBlue {
    return [UIColor colorWithRed:0.29f green:0.59f blue:0.82f alpha:1.0f];
}

+ (UIColor *)cerise {
    return [UIColor colorWithRed:0.87f green:0.19f blue:0.39f alpha:1.0f];
}

+ (UIColor *)cerisePink {
    return [UIColor colorWithRed:0.93f green:0.23f blue:0.51f alpha:1.0f];
}

+ (UIColor *)cerulean {
    return [UIColor colorWithRed:0.0f green:0.48f blue:0.65f alpha:1.0f];
}

+ (UIColor *)ceruleanBlue {
    return [UIColor colorWithRed:0.16f green:0.32f blue:0.75f alpha:1.0f];
}

+ (UIColor *)ceruleanFrost {
    return [UIColor colorWithRed:0.43f green:0.61f blue:0.76f alpha:1.0f];
}

+ (UIColor *)cgBlue {
    return [UIColor colorWithRed:0.0f green:0.48f blue:0.65f alpha:1.0f];
}

+ (UIColor *)cgRed {
    return [UIColor colorWithRed:0.88f green:0.24f blue:0.19f alpha:1.0f];
}

+ (UIColor *)chamoisee {
    return [UIColor colorWithRed:0.63f green:0.47f blue:0.35f alpha:1.0f];
}

+ (UIColor *)champagne {
    return [UIColor colorWithRed:0.97f green:0.91f blue:0.81f alpha:1.0f];
}

+ (UIColor *)charcoal {
    return [UIColor colorWithRed:0.21f green:0.27f blue:0.31f alpha:1.0f];
}

+ (UIColor *)charlestonGreen {
    return [UIColor colorWithRed:0.14f green:0.17f blue:0.17f alpha:1.0f];
}

+ (UIColor *)charmPink {
    return [UIColor colorWithRed:0.90f green:0.56f blue:0.67f alpha:1.0f];
}

+ (UIColor *)chartreuse {
    return [UIColor colorWithRed:0.87f green:1.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)chartreuseWeb {
    return [UIColor colorWithRed:0.50f green:1.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)cherry {
    return [UIColor colorWithRed:0.87f green:0.19f blue:0.39f alpha:1.0f];
}

+ (UIColor *)cherryBlossomPink {
    return [UIColor colorWithRed:1.0f green:0.72f blue:0.77f alpha:1.0f];
}

+ (UIColor *)chestnut {
    return [UIColor colorWithRed:0.58f green:0.27f blue:0.21f alpha:1.0f];
}

+ (UIColor *)chinaPink {
    return [UIColor colorWithRed:0.87f green:0.44f blue:0.63f alpha:1.0f];
}

+ (UIColor *)chinaRose {
    return [UIColor colorWithRed:0.66f green:0.32f blue:0.43f alpha:1.0f];
}

+ (UIColor *)chineseRed {
    return [UIColor colorWithRed:0.67f green:0.22f blue:0.12f alpha:1.0f];
}

+ (UIColor *)chineseViolet {
    return [UIColor colorWithRed:0.52f green:0.38f blue:0.53f alpha:1.0f];
}

+ (UIColor *)chocolate {
    return [UIColor colorWithRed:0.48f green:0.25f blue:0.0f alpha:1.0f];
}

+ (UIColor *)chocolateWeb {
    return [UIColor colorWithRed:0.82f green:0.41f blue:0.12f alpha:1.0f];
}

+ (UIColor *)chromeYellow {
    return [UIColor colorWithRed:1.0f green:0.65f blue:0.00f alpha:1.0f];
}

+ (UIColor *)cinerous {
    return [UIColor colorWithRed:0.60f green:0.51f blue:0.48f alpha:1.0f];
}

+ (UIColor *)cinnabar {
    return [UIColor colorWithRed:0.89f green:0.26f blue:0.20f alpha:1.0f];
}

+ (UIColor *)cinnamon {
    return [UIColor colorWithRed:0.82f green:0.41f blue:0.12f alpha:1.0f];
}

+ (UIColor *)citrine {
    return [UIColor colorWithRed:0.89f green:0.82f blue:0.04f alpha:1.0f];
}

+ (UIColor *)citron {
    return [UIColor colorWithRed:0.62f green:0.66f blue:0.12f alpha:1.0f];
}

+ (UIColor *)claret {
    return [UIColor colorWithRed:0.50f green:0.09f blue:0.20f alpha:1.0f];
}

+ (UIColor *)classicRose {
    return [UIColor colorWithRed:0.98f green:0.80f blue:0.91f alpha:1.0f];
}

+ (UIColor *)cobalt {
    return [UIColor colorWithRed:0.0f green:0.28f blue:0.67f alpha:1.0f];
}

+ (UIColor *)cocoaBrown {
    return [UIColor colorWithRed:0.82f green:0.41f blue:0.12f alpha:1.0f];
}

+ (UIColor *)coconut {
    return [UIColor colorWithRed:0.59f green:0.35f blue:0.24f alpha:1.0f];
}

+ (UIColor *)coffee {
    return [UIColor colorWithRed:0.44f green:0.31f blue:0.22f alpha:1.0f];
}

+ (UIColor *)columbiaBlue {
    return [UIColor colorWithRed:0.77f green:0.85f blue:0.89f alpha:1.0f];
}

+ (UIColor *)congoPink {
    return [UIColor colorWithRed:0.97f green:0.51f blue:0.47f alpha:1.0f];
}

+ (UIColor *)coolBlack {
    return [UIColor colorWithRed:0.00f green:0.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)coolGrey {
    return [UIColor colorWithRed:0.55f green:0.57f blue:0.67f alpha:1.0];
}

+ (UIColor *)copper {
    return [UIColor colorWithRed:0.72f green:0.45f blue:0.20f alpha:1.0f];
}

+ (UIColor *)copperCrayola {
    return [UIColor colorWithRed:0.85f green:0.54f blue:0.40f alpha:1.0f];
}

+ (UIColor *)copperPenny {
    return [UIColor colorWithRed:0.68f green:0.44f blue:0.41f alpha:1.0f];
}

+ (UIColor *)copperRed {
    return [UIColor colorWithRed:0.80f green:0.43f blue:0.32f alpha:1.0f];
}

+ (UIColor *)copperRose {
    return [UIColor colorWithRed:0.60f green:0.40f blue:0.40f alpha:1.0f];
}

+ (UIColor *)coquelicot {
    return [UIColor colorWithRed:1.0f green:0.22f blue:0.0f alpha:1.0f];
}

+ (UIColor *)coral {
    return [UIColor colorWithRed:1.0f green:0.50f blue:0.31f alpha:1.0f];
}

+ (UIColor *)coralPink {
    return [UIColor colorWithRed:0.97f green:0.51f blue:0.47f alpha:1.0f];
}

+ (UIColor *)coralRed {
    return [UIColor colorWithRed:1.0f green:0.25f blue:0.25f alpha:1.0f];
}

+ (UIColor *)cordovan {
    return [UIColor colorWithRed:0.54f green:0.25f blue:0.27f alpha:1.0f];
}

+ (UIColor *)corn {
    return [UIColor colorWithRed:0.98f green:0.93f blue:0.36f alpha:1.0f];
}

+ (UIColor *)cornellRed {
    return [UIColor colorWithRed:0.7f green:0.11f blue:0.11f alpha:1.0f];
}

+ (UIColor *)cornflowerBlue {
    return [UIColor colorWithRed:0.39f green:0.58f blue:0.93f alpha:1.0f];
}

+ (UIColor *)conrsilk {
    return [UIColor colorWithRed:1.0f green:0.97f blue:0.86f alpha:1.0f];
}

+ (UIColor *)cosmicLatte {
    return [UIColor colorWithRed:1.0f green:0.97f blue:0.91f alpha:1.0f];
}

+ (UIColor *)coyoteBrown {
    return [UIColor colorWithRed:0.51f green:0.38f blue:0.24f alpha:1.0f];
}

+ (UIColor *)cottonCandy {
    return [UIColor colorWithRed:1.0f green:0.74f blue:0.85f alpha:1.0f];
}

+ (UIColor *)cream {
    return [UIColor colorWithRed:1.0f green:0.99f blue:0.82f alpha:1.0f];
}

+ (UIColor *)crimson {
    return [UIColor colorWithRed:0.86f green:0.08f blue:0.24f alpha:1.0f];
}

+ (UIColor *)crimsonGlory {
    return [UIColor colorWithRed:0.75f green:0.0f blue:0.20f alpha:1.0f];
}

+ (UIColor *)crimsonRed {
    return [UIColor colorWithRed:0.60f green:0.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)cyan {
    return [UIColor colorWithRed:0.0f green:1.0f blue:1.0f alpha:1.0f];
}

+ (UIColor *)cyanAzure {
    return [UIColor colorWithRed:0.31f green:0.51f blue:0.71f alpha:1.0f];
}

+ (UIColor *)cyanCobaltBlue {
    return [UIColor colorWithRed:0.16f green:0.35f blue:0.61f alpha:1.0f];
}

+ (UIColor *)cyanCornflowerBlue {
    return [UIColor colorWithRed:0.09f green:0.55f blue:0.76f alpha:1.0f];
}

+ (UIColor *)cyanProcess {
    return [UIColor colorWithRed:0.0f green:0.72f blue:0.92f alpha:1.0f];
}

+ (UIColor *)cyberGrape {
    return [UIColor colorWithRed:0.35f green:0.26f blue:0.49f alpha:1.0f];
}

+ (UIColor *)cyberYellow {
    return [UIColor colorWithRed:1.0f green:0.83f blue:0.0f alpha:1.0f];
}

+ (UIColor *)daffodil {
    return [UIColor colorWithRed:1.0f green:1.0f blue:0.19f alpha:1.0f];
}

+ (UIColor *)dandelion {
    return [UIColor colorWithRed:0.94f green:0.88f blue:0.19f alpha:1.0f];
}

+ (UIColor *)darkBlue {
    return [UIColor colorWithRed:0.0f green:0.0f blue:0.55f alpha:1.0f];
}

+ (UIColor *)darkBlueGray {
    return [UIColor colorWithRed:0.4f green:0.4f blue:0.6f alpha:1.0f];
}

+ (UIColor *)darkBrown {
    return [UIColor colorWithRed:0.4f green:0.26f blue:0.13f alpha:1.0f];
}

+ (UIColor *)darkByzantium {
    return [UIColor colorWithRed:0.36f green:0.22f blue:0.33f alpha:1.0f];
}

+ (UIColor *)darkCandyAppleRed {
    return [UIColor colorWithRed:0.64f green:0.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)darkCerulean {
    return [UIColor colorWithRed:0.03f green:0.27f blue:0.49f alpha:1.0f];
}

+ (UIColor *)darkChestnut {
    return [UIColor colorWithRed:0.6f green:0.41f blue:0.38f alpha:1.0f];
}

+ (UIColor *)darkCoral {
    return [UIColor colorWithRed:0.8f green:0.36f blue:0.27f alpha:1.0f];
}

+ (UIColor *)darkCyan {
    return [UIColor colorWithRed:0.0f green:0.55f blue:0.55f alpha:1.0f];
}

+ (UIColor *)darkElectricBlue {
    return [UIColor colorWithRed:0.33f green:0.41f blue:0.47f alpha:1.0f];
}

+ (UIColor *)darkGoldenrod {
    return [UIColor colorWithRed:0.72f green:0.53f blue:0.04f alpha:1.0f];
}

+ (UIColor *)darkGray {
    return [UIColor colorWithWhite:2/3.0f alpha:1.0f];
}

+ (UIColor *)darkGreen {
    return [UIColor colorWithRed:0.0f green:0.2f blue:0.13f alpha:1.0f];
}

+ (UIColor *)darkImperialBlue {
    return [UIColor colorWithRed:0.0f green:0.25f blue:0.42f alpha:1.0f];
}

+ (UIColor *)darkJungleGreen {
    return [UIColor colorWithRed:0.1f green:0.14f blue:0.13f alpha:1.0f];
}

+ (UIColor *)darkKhaki {
    return [UIColor colorWithRed:0.74f green:0.72f blue:0.42f alpha:1.0f];
}

+ (UIColor *)darkLava {
    return [UIColor colorWithRed:0.28f green:0.24f blue:0.2f alpha:1.0f];
}

+ (UIColor *)darkLavendar {
    return [UIColor colorWithRed:0.45f green:0.31f blue:0.59f alpha:1.0f];
}

+ (UIColor *)darkLiver {
    return [UIColor colorWithRed:0.33f green:0.29f blue:0.31f alpha:1.0f];
}

+ (UIColor *)darkLiverHorses {
    return [UIColor colorWithRed:0.33f green:0.24f blue:0.22f alpha:1.0f];
}

+ (UIColor *)darkMagenta {
    return [UIColor colorWithRed:0.55f green:0.0f blue:0.55f alpha:1.0f];
}

+ (UIColor *)darkMediumGray {
    return [UIColor darkGray];
}

+ (UIColor *)darkMidnightBlue {
    return [UIColor colorWithRed:0.0f green:0.2f blue:0.4f alpha:1.0f];
}

+ (UIColor *)darkMossGreen {
    return [UIColor colorWithRed:0.29f green:0.36f blue:0.14f alpha:1.0f];
}

+ (UIColor *)darkOliveGreen {
    return [UIColor colorWithRed:0.33f green:0.42f blue:0.18f alpha:1.0f];
}

+ (UIColor *)darkOrange {
    return [UIColor colorWithRed:1.0f green:0.55f blue:0.0f alpha:1.0f];
}

+ (UIColor *)darkOrchid {
    return [UIColor colorWithRed:0.6f green:0.2f blue:0.8f alpha:1.0f];
}

+ (UIColor *)darkPastelBlue {
    return [UIColor colorWithRed:0.47f green:0.62f blue:0.8f alpha:1.0f];
}

+ (UIColor *)darkPastelGreen {
    return [UIColor colorWithRed:0.01f green:0.75f blue:0.24f alpha:1.0f];
}

+ (UIColor *)darkPastelPurple {
    return [UIColor colorWithRed:0.59f green:0.44f blue:0.84f alpha:1.0f];
}

+ (UIColor *)darkPastelRed {
    return [UIColor colorWithRed:0.76f green:0.23f blue:0.13f alpha:1.0f];
}

+ (UIColor *)darkPink {
    return [UIColor colorWithRed:0.91f green:1/3.0f blue:0.5f alpha:1.0f];
}

+ (UIColor *)darkPowderBlue {
    return [UIColor colorWithRed:0.0f green:0.2f blue:0.6f alpha:1.0f];
}

+ (UIColor *)darkPuce {
    return [UIColor colorWithRed:0.31f green:0.23f blue:0.24f alpha:1.0f];
}

+ (UIColor *)darkRaspberry {
    return [UIColor colorWithRed:0.53f green:0.15f blue:0.34f alpha:1.0f];
}

+ (UIColor *)darkRed {
    return [UIColor colorWithRed:0.55f green:0.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)darkSalmon {
    return [UIColor colorWithRed:0.91f green:0.59f blue:0.48f alpha:1.0f];
}

+ (UIColor *)darkScarlet {
    return [UIColor colorWithRed:0.34f green:0.01f blue:0.10f alpha:1.0f];
}

+ (UIColor *)darkSeaGreen {
    return [UIColor colorWithRed:0.56f green:0.74f blue:0.56f alpha:1.0f];
}

+ (UIColor *)darkSienna {
    return [UIColor colorWithRed:0.24f green:0.08f blue:0.08f alpha:1.0f];
}

+ (UIColor *)darkSkyBlue {
    return [UIColor colorWithRed:0.55f green:0.75f blue:0.84f alpha:1.0f];
}

+ (UIColor *)darkSlateBlue {
    return [UIColor colorWithRed:0.28f green:0.24f blue:0.55f alpha:1.0f];
}

+ (UIColor *)darkSlateGray {
    return [UIColor colorWithRed:0.18f green:0.31f blue:0.31f alpha:1.0f];
}

+ (UIColor *)darkSpringGreen {
    return [UIColor colorWithRed:0.09f green:0.45f blue:0.27f alpha:1.0f];
}

+ (UIColor *)darkTan {
    return [UIColor colorWithRed:0.57f green:0.51f blue:0.32f alpha:1.0f];
}

+ (UIColor *)darkTangerine {
    return [UIColor colorWithRed:1.0f green:0.66f blue:0.07f alpha:1.0f];
}

+ (UIColor *)darkTaupe {
    return [UIColor colorWithRed:0.28f green:0.24f blue:0.2f alpha:1.0f];
}

+ (UIColor *)darkTerraCotta {
    return [UIColor colorWithRed:0.8f green:0.31f blue:0.36f alpha:1.0f];
}

+ (UIColor *)darkTurquoise {
    return [UIColor colorWithRed:0.0f green:0.81f blue:0.82f alpha:1.0f];
}

+ (UIColor *)darkVanilla {
    return [UIColor colorWithRed:0.82f green:0.75f blue:0.66f alpha:1.0f];
}

+ (UIColor *)darkViolet {
    return [UIColor colorWithRed:0.58f green:0.0f blue:0.83f alpha:1.0f];
}

+ (UIColor *)darkYellow {
    return [UIColor colorWithRed:0.61f green:0.53f blue:0.05f alpha:1.0f];
}

+ (UIColor *)dartmouthGreen {
    return [UIColor colorWithRed:0.0f green:0.44f blue:0.24f alpha:1.0f];
}

+ (UIColor *)davysGrey {
    return [UIColor colorWithWhite:1/3.0f alpha:1.0f];
}

+ (UIColor *)debianRed {
    return [UIColor colorWithRed:0.84f green:0.04f blue:1/3.0f alpha:1.0f];
}

+ (UIColor *)deepAquamarine {
    return [UIColor colorWithRed:0.25f green:0.51f blue:0.43f alpha:1.0f];
}

+ (UIColor *)deepCarmine {
    return [UIColor colorWithRed:2/3.0f green:0.13f blue:0.24f alpha:1.0f];
}

+ (UIColor *)deepCarminePink {
    return [UIColor colorWithRed:0.94f green:0.19f blue:0.22f alpha:1.0f];
}

+ (UIColor *)deepCarrotOrange {
    return [UIColor colorWithRed:0.91f green:0.41f blue:0.17f alpha:1.0f];
}

+ (UIColor *)deepCerise {
    return [UIColor colorWithRed:0.85f green:0.20f blue:0.53f alpha:1.0f];
}

+ (UIColor *)deepChampagne {
    return [UIColor colorWithRed:0.98f green:0.84f blue:0.65f alpha:1.0f];
}

+ (UIColor *)deepChestnut {
    return [UIColor colorWithRed:0.73f green:0.31f blue:0.28f alpha:1.0f];
}

+ (UIColor *)deepCoffee {
    return [UIColor colorWithRed:0.44f green:0.26f blue:0.25f alpha:1.0f];
}

+ (UIColor *)deepFuchsia {
    return [UIColor colorWithRed:0.76f green:1/3.0f blue:0.76f alpha:1.0f];
}

+ (UIColor *)deepGreen {
    return [UIColor colorWithRed:0.02f green:0.40f blue:1/33.0f alpha:1.0f];
}

+ (UIColor *)deepGreenCyanTurquoise {
    return [UIColor colorWithRed:0.05f green:0.49f blue:0.38f alpha:1.0f];
}

+ (UIColor *)deepJungleGreen {
    return [UIColor colorWithRed:0.0f green:0.29f blue:0.29f alpha:1.0f];
}

+ (UIColor *)deepKamaru {
    return [UIColor colorWithRed:0.20f green:0.20f blue:0.40f alpha:1.0f];
}

+ (UIColor *)deepLemon {
    return [UIColor colorWithRed:0.96f green:0.78f blue:0.10f alpha:1.0f];
}

+ (UIColor *)deepLilac {
    return [UIColor colorWithRed:0.60f green:1/3.0f blue:0.73f alpha:1.0f];
}

+ (UIColor *)deepMagenta {
    return [UIColor colorWithRed:0.80f green:0.0f blue:0.80f alpha:1.0f];
}

+ (UIColor *)deepMaroon {
    return [UIColor colorWithRed:0.51f green:0.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)deepMauve {
    return [UIColor colorWithRed:0.83f green:0.45f blue:0.83f alpha:1.0f];
}

+ (UIColor *)deepMossGreen {
    return [UIColor colorWithRed:0.21f green:0.37f blue:0.23f alpha:1.0f];
}

+ (UIColor *)deepPeach {
    return [UIColor colorWithRed:1.0f green:0.8f blue:0.64f alpha:1.0f];
}

+ (UIColor *)deepPink {
    return [UIColor colorWithRed:1.0f green:0.08f blue:0.58f alpha:1.0f];
}

+ (UIColor *)deepPuce {
    return [UIColor colorWithRed:2/3.0f green:0.36f blue:0.41f alpha:1.0f];
}

+ (UIColor *)deepRed {
    return [UIColor colorWithRed:0.52f green:0.0f blue:0.0f alpha:1.0f];
}

+ (UIColor *)deepRuby {
    return [UIColor colorWithRed:0.52f green:0.25f blue:0.36f alpha:1.0f];
}

+ (UIColor *)deepSaffron {
    return [UIColor colorWithRed:1.0f green:0.6f blue:0.20f alpha:1.0f];
}

+ (UIColor *)deepSkyBlue {
    return [UIColor colorWithRed:0.0f green:0.75f blue:1.0f alpha:1.0f];
}

+ (UIColor *)deepSpaceSparkle {
    return [UIColor colorWithRed:0.29f green:0.39f blue:0.42f alpha:1.0f];
}

+ (UIColor *)deepSpringBud {
    return [UIColor colorWithRed:1/3.0f green:0.42f blue:0.18f alpha:1.0f];
}

+ (UIColor *)deepTaupe {
    return [UIColor colorWithRed:0.49f green:0.37f blue:0.38f alpha:1.0f];
}

+ (UIColor *)deepTuscanRed {
    return [UIColor colorWithRed:0.40f green:0.26f blue:0.30f alpha:1.0f];
}

+ (UIColor *)deer {
    return [UIColor colorWithRed:0.73f green:0.53f blue:0.35f alpha:1.0f];
}

+ (UIColor *)denim {
    return [UIColor colorWithRed:0.08f green:0.38f blue:0.74f alpha:1.0f];
}

+ (UIColor *)desaturatedCyan {
    return [UIColor colorWithRed:0.40f green:0.60f blue:0.60f alpha:1.0f];
}

+ (UIColor *)desert {
    return [UIColor colorWithRed:0.76f green:0.60f blue:0.42f alpha:1.0f];
}

+ (UIColor *)desertSand {
    return [UIColor colorWithRed:0.93f green:0.79f blue:0.69f alpha:1.0f];
}

+ (UIColor *)desire {
    return [UIColor colorWithRed:0.92f green:0.24f blue:0.33f alpha:1.0f];
}

+ (UIColor *)diamond {
    return [UIColor colorWithRed:0.73f green:0.95f blue:1.0f alpha:1.0f];
}

+ (UIColor *)dimGray {
    return [UIColor colorWithWhite:0.41f alpha:1.0f];
}

+ (UIColor *)dirt {
    return [UIColor colorWithRed:0.61f green:0.46f blue:1/3.0f alpha:1.0f];
}

+ (UIColor *)dodgerBlue {
    return [UIColor colorWithRed:0.12f green:0.56f blue:1.0f alpha:1.0f];
}

+ (UIColor *)dogwoodRose {
    return [UIColor colorWithRed:0.84f green:0.09f blue:0.41f alpha:1.0f];
}

+ (UIColor *)dollarBill {
    return [UIColor colorWithRed:0.52f green:0.73f blue:0.40f alpha:1.0f];
}

+ (UIColor *)donkeyBrown {
    return [UIColor colorWithRed:0.40f green:0.30f blue:0.16f alpha:1.0f];
}

+ (UIColor *)drab {
    return [UIColor colorWithRed:0.59f green:0.44f blue:0.09f alpha:1.0f];
}

+ (UIColor *)dukeBlue {
    return [UIColor colorWithRed:0.0f green:0.0f blue:0.61f alpha:1.0f];
}

+ (UIColor *)dustStorm {
    return [UIColor colorWithRed:0.90f green:0.80f blue:0.79f alpha:1.0f];
}

+ (UIColor *)dutchWhite {
    return [UIColor colorWithRed:0.94f green:0.87f blue:0.73f alpha:1.0f];
}











@end
