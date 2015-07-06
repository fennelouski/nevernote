//
//  UNITaskCreatorViewController.h
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UNITaskCreatorViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate>

- (instancetype)initWithNumberOfAccounts:(int)numberOfAccounts;

@end
