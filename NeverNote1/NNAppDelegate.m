//
//  NNAppDelegate.m
//  NeverNote
//
//  Created by Nathan Fennel on 5/4/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "NNAppDelegate.h"
#import "NNViewController.h"
#import "NNOnboardingManager.h"
#import "NNOnboardingCoordinator.h"
#import "NNLogoTraceView.h"
#import "UIColor+AppColors.h"

@interface NNAppDelegate ()

@property (nonatomic, strong, nullable) NNLogoTraceView *logoTraceView;
@property (nonatomic, assign) BOOL hasShownLaunchAnimation;

@end

@implementation NNAppDelegate

@synthesize persistentContainer = _persistentContainer;
@synthesize managedObjectContext = _managedObjectContext;

+ (UIViewController *)nn_keyWindowRootViewController {
    NSSet<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene *scene in scenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window.rootViewController;
            }
        }
        if (windowScene.windows.count > 0) {
            return windowScene.windows.firstObject.rootViewController;
        }
    }
    return nil;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if NEVERNOTE_SWIFTUI_ROOT
    return YES;
#else
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.tintColor = [UIColor appIconBlueColor];
    
    NNViewController *mainViewController = [[NNViewController alloc] init];
    
    self.window.backgroundColor = [UIColor whiteColor];

    [self.window setRootViewController:mainViewController];

    [self.window makeKeyAndVisible];
    [self showLaunchAnimationIfNeeded];

    // Setup onboarding coordinator
    [NNOnboardingCoordinator sharedCoordinator].rootViewController = mainViewController;

    return YES;
#endif
}

- (void)showLaunchAnimationIfNeeded {
    if (self.hasShownLaunchAnimation || !self.window) {
        return;
    }

    self.hasShownLaunchAnimation = YES;

    NNLogoTraceView *traceView = [[NNLogoTraceView alloc] initWithFrame:self.window.bounds];
    traceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    traceView.backgroundColor = self.window.backgroundColor;
    [self.window addSubview:traceView];
    self.logoTraceView = traceView;

    __weak typeof(self) weakSelf = self;
    [traceView startAnimationWithCompletion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf removeLaunchAnimationOverlay];
    }];

    NSTimeInterval failSafe = [NNLogoTraceView launchHandoffTotalDuration] + 0.2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(failSafe * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf removeLaunchAnimationOverlay];
    });
}

- (void)removeLaunchAnimationOverlay {
    if (!self.logoTraceView) {
        return;
    }
    [self.logoTraceView removeFromSuperview];
    self.logoTraceView = nil;
}

- (void)applicationWillResignActive:(UIApplication *)application
{

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
#if NEVERNOTE_SWIFTUI_ROOT
    return;
#else
    NNViewController *mainViewController = [[NNViewController alloc] init];
    
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.tintColor = [UIColor appIconBlueColor];
    
    [self.window setRootViewController:mainViewController];
#endif
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    // Update last app use date
    [[NNOnboardingManager sharedManager] updateLastAppUseDate];

#if NEVERNOTE_SWIFTUI_ROOT
    UIViewController *root = [NNAppDelegate nn_keyWindowRootViewController];
    if (root != nil) {
        [NNOnboardingCoordinator sharedCoordinator].rootViewController = root;
    }
#endif

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
