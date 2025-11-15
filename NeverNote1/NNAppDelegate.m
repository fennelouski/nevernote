//
//  NNAppDelegate.m
//  NeverNote
//
//  Created by Nathan Fennel on 5/4/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "NNAppDelegate.h"
#import "NNViewController.h"
#import "UNITaskCreatorViewController.h"
#import "NNListViewController.h"
#import "NNOnboardingManager.h"
#import "NNOnboardingCoordinator.h"

@implementation NNAppDelegate

@synthesize persistentContainer = _persistentContainer;
@synthesize managedObjectContext = _managedObjectContext;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIViewController *vc;
    
    NNViewController *mainViewController = [[NNViewController alloc] init];
    UNITaskCreatorViewController *taskCreatorViewController = [[UNITaskCreatorViewController alloc] initWithNumberOfAccounts:2];
    NNListViewController *listViewController = [[NNListViewController alloc] init];
    vc = listViewController;
    
    self.window.backgroundColor = [UIColor whiteColor];

    [self.window setRootViewController:vc];

    [self.window makeKeyAndVisible];

    // Setup onboarding coordinator
    [NNOnboardingCoordinator sharedCoordinator].rootViewController = vc;

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NNViewController *mainViewController = [[NNViewController alloc] init];
    
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self.window setRootViewController:mainViewController];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    // Update last app use date
    [[NNOnboardingManager sharedManager] updateLastAppUseDate];

    // Check if onboarding should be shown
    [[NNOnboardingCoordinator sharedCoordinator] checkAndStartOnboarding];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.window.rootViewController removeFromParentViewController];
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSManagedObjectContext *context = self.managedObjectContext;
    if (context != nil) {
        NSError *error = nil;
        if ([context hasChanges] && ![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Modern Core Data stack using NSPersistentContainer (iOS 10+)
- (NSPersistentContainer *)persistentContainer {
    if (@available(iOS 10.0, *)) {
        if (_persistentContainer != nil) {
            return _persistentContainer;
        }

        _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"NeverNote"];

        [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
            if (error != nil) {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }];

        return _persistentContainer;
    }
    return nil;
}

// Returns the managed object context for the application.
// Uses NSPersistentContainer on iOS 10+
- (NSManagedObjectContext *)managedObjectContext {
    if (@available(iOS 10.0, *)) {
        if (_managedObjectContext == nil) {
            _managedObjectContext = self.persistentContainer.viewContext;
        }
        return _managedObjectContext;
    }
    return nil;
}

- (CMMotionManager *)motionManager {
    if (!motionManager) {
        motionManager = [[CMMotionManager alloc] init];
    }

    return motionManager;
}

@end
