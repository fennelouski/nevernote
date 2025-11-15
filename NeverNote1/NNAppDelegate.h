//
//  NNAppDelegate.h
//  NeverNote
//
//  Created by Nathan Fennel on 5/4/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@interface NNAppDelegate : UIResponder <UIApplicationDelegate> {
    CMMotionManager *motionManager;
}

@property (readonly) CMMotionManager *motionManager;

@property (strong, nonatomic) UIWindow *window;

// Modern Core Data stack (iOS 10+)
@property (strong, nonatomic) NSPersistentContainer *persistentContainer API_AVAILABLE(ios(10.0));

// Legacy Core Data properties for backward compatibility
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)saveContext;

@end
